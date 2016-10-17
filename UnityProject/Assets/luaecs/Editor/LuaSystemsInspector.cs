using Entitas.Unity;
using System;
using System.Linq;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using LuaInterface;
using Entitas.Unity.VisualDebugging;

namespace SuperMobs.Game.Lua.Editor
{
    [CustomEditor(typeof(LuaSystems))]
    public class LuaSystemsInspector : UnityEditor.Editor
    {
        const int SYSTEM_MONITOR_DATA_LENGTH = 60;
        SystemsMonitor _systemsMonitor;
        Queue<float> _systemMonitorData;

        static bool _showInitializeSystems = true;
        static bool _showExecuteSystems = true;
        static string _systemNameSearchTerm = string.Empty;

        float _threshold;
        bool _sortSystemInfos;

        public override void OnInspectorGUI()
        {
            string systemsName = (target as LuaSystems).systemsName;
            drawSystemsOverview(systemsName);
            drawSystemsMonitor(systemsName);
            drawSystemList(systemsName);
        }

        static void drawSystemsOverview(string systemsName)
        {
            EntitasEditorLayout.BeginVerticalBox();
            {
                EditorGUILayout.LabelField(systemsName, EditorStyles.boldLabel);
                EditorGUILayout.LabelField("Initialize Systems", Convert.ToInt32(LuaSystems.GetProfile(systemsName)["initializesystemcount"]).ToString());
                EditorGUILayout.LabelField("Execute Systems", Convert.ToInt32(LuaSystems.GetProfile(systemsName)["executesystemcount"]).ToString());
                EditorGUILayout.LabelField("Total Systems", Convert.ToInt32(LuaSystems.GetProfile(systemsName)["allsystemcount"]).ToString());
            }
            EntitasEditorLayout.EndVertical();
        }

        void drawSystemsMonitor(string systemsName)
        {
            if (_systemsMonitor == null)
            {
                _systemsMonitor = new SystemsMonitor(SYSTEM_MONITOR_DATA_LENGTH);
                _systemMonitorData = new Queue<float>(new float[SYSTEM_MONITOR_DATA_LENGTH]);
                if (EditorApplication.update != Repaint)
                {
                    EditorApplication.update += Repaint;
                }
            }

            EntitasEditorLayout.BeginVerticalBox();
            {
                EditorGUILayout.LabelField("Execution duration", EditorStyles.boldLabel);

                EntitasEditorLayout.BeginHorizontal();
                {
                    EditorGUILayout.LabelField("Total", string.Format("{0:0.000}", LuaSystems.GetProfile(systemsName)["executecostnow"]));

                    var buttonStyle = new GUIStyle(GUI.skin.button);
                    if (!(bool)LuaSystems.GetProfile(systemsName)["enable"])
                    {
                        buttonStyle.normal = GUI.skin.button.active;
                    }
                    if (GUILayout.Button("▌▌", buttonStyle, GUILayout.Width(50)))
                    {
                        LuaSystems.GetProfile(systemsName)["enable"] = !(bool)LuaSystems.GetProfile(systemsName)["enable"];
                    }

                    if (GUILayout.Button("Step", GUILayout.Width(50)))
                    {
                        LuaSystems.Step(systemsName);
                    }
                }
                EntitasEditorLayout.EndHorizontal();

                if (!EditorApplication.isPaused)
                {
                    LuaSystems systems = target as LuaSystems;
                    if ((bool)LuaSystems.GetProfile(systemsName)["enable"])
                    {
                        addDuration(Convert.ToSingle(LuaSystems.GetProfile(systemsName)["executecostnow"]));
                    }
                    else if (systems.stepState == LuaSystems.StepState.Over)
                    {
                        systems.stepState = LuaSystems.StepState.Disable;
                        addDuration(Convert.ToSingle(LuaSystems.GetProfile(systemsName)["executecostnow"]));
                    }
                }
                _systemsMonitor.Draw(_systemMonitorData.ToArray(), 80f);
            }
            EntitasEditorLayout.EndVertical();
        }

        void drawSystemList(string systemsName)
        {
            EntitasEditorLayout.BeginVertical();
            {
                EntitasEditorLayout.BeginHorizontal();
                {
                    LuaSystems ls = target as LuaSystems;
                    ls.avgResetInterval = (AvgResetInterval)EditorGUILayout.EnumPopup("Reset average duration Ø", ls.avgResetInterval);
                    if (GUILayout.Button("Reset Ø now", GUILayout.Width(88), GUILayout.Height(14)))
                    {
                        LuaSystems.Reset(systemsName);
                    }
                }
                EntitasEditorLayout.EndHorizontal();

                _threshold = EditorGUILayout.Slider("Threshold Ø ms", _threshold, 0f, 33f);
                _sortSystemInfos = EditorGUILayout.Toggle("Sort by execution duration", _sortSystemInfos);
                EditorGUILayout.Space();

                EntitasEditorLayout.BeginHorizontal();
                {
                    _systemNameSearchTerm = EditorGUILayout.TextField("Search", _systemNameSearchTerm);

                    const string clearButtonControlName = "Clear Button";
                    GUI.SetNextControlName(clearButtonControlName);
                    if (GUILayout.Button("x", GUILayout.Width(19), GUILayout.Height(14)))
                    {
                        _systemNameSearchTerm = string.Empty;
                        GUI.FocusControl(clearButtonControlName);
                    }
                }
                EntitasEditorLayout.EndHorizontal();

                _showInitializeSystems = EditorGUILayout.Foldout(_showInitializeSystems, "Initialize Systems");
                if (_showInitializeSystems)
                {
                    EntitasEditorLayout.BeginVerticalBox();
                    {
                        var systemsDrawn = drawSystemInfos(systemsName, true, false);
                        if (systemsDrawn == 0)
                        {
                            EditorGUILayout.LabelField(string.Empty);
                        }
                    }
                    EntitasEditorLayout.EndVertical();
                }

                _showExecuteSystems = EditorGUILayout.Foldout(_showExecuteSystems, "Execute Systems");
                if (_showExecuteSystems)
                {
                    EntitasEditorLayout.BeginVerticalBox();
                    {
                        var systemsDrawn = drawSystemInfos(systemsName, false, false);
                        if (systemsDrawn == 0)
                        {
                            EditorGUILayout.LabelField(string.Empty);
                        }
                    }
                    EntitasEditorLayout.EndVertical();
                }
            }
            EntitasEditorLayout.EndVertical();
        }

        int drawSystemInfos(string systemsName, bool initOnly, bool isChildSysem)
        {
            string[] names = initOnly ? LuaSystems.GetInitializeChildNameList(systemsName) : LuaSystems.GetExecuteChildNameList(systemsName);
            names = names
                .Where(name => { return LuaSystems.GetAverageCost(name) >= _threshold; })
                .ToArray();

            if (_sortSystemInfos)
            {
                names = names
                    .OrderByDescending(name => LuaSystems.GetAverageCost(name))
                    .ToArray();
            }

            var systemsDrawn = 0;
            foreach (var name in names)
            {
                if (name.ToLower().Contains(_systemNameSearchTerm.ToLower()))
                {
                    EntitasEditorLayout.BeginHorizontal();
                    {
                        LuaTable profile = LuaSystems.GetProfile(name);
                        EditorGUI.BeginDisabledGroup(isChildSysem);
                        {
                            profile["enable"] = EditorGUILayout.Toggle(Convert.ToBoolean(profile["enable"]), GUILayout.Width(20));
                        }
                        EditorGUI.EndDisabledGroup();

                        float initCost = Convert.ToSingle(profile["initializecost"]);
                        var avg = string.Format("Ø {0:0.000}", initOnly ? initCost : LuaSystems.GetAverageCost(name)).PadRight(9);
                        var min = string.Format("min {0:0.000}", initOnly ? initCost : Convert.ToSingle(profile["executecostmin"])).PadRight(11);
                        var max = string.Format("max {0:0.000}", initOnly ? initCost : Convert.ToSingle(profile["executecostmax"]));
                        EditorGUILayout.LabelField(name, avg + "\t" + min + "\t" + max, getSystemStyle(name));
                    }
                    EntitasEditorLayout.EndHorizontal();

                    systemsDrawn += 1;
                }

                if (LuaSystems.IsSystems(name))
                {
                    var indent = EditorGUI.indentLevel;
                    EditorGUI.indentLevel += 1;
                    systemsDrawn += drawSystemInfos(name, initOnly, true);
                    EditorGUI.indentLevel = indent;
                }
            }

            return systemsDrawn;
        }

        void addDuration(float duration)
        {
            if (_systemMonitorData.Count >= SYSTEM_MONITOR_DATA_LENGTH)
            {
                _systemMonitorData.Dequeue();
            }

            _systemMonitorData.Enqueue(duration);
        }

        static GUIStyle getSystemStyle(string name)
        {
            var style = new GUIStyle(GUI.skin.label);
            var color = LuaSystems.IsReactive(name) && EditorGUIUtility.isProSkin
                            ? Color.white
                            : style.normal.textColor;

            style.normal.textColor = color;

            return style;
        }
    }
}