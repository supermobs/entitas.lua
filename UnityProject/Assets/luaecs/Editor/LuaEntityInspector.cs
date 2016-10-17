using Entitas.Unity;
using Entitas.Unity.VisualDebugging;
using LuaInterface;
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace SuperMobs.Game.Lua.Editor
{
    [CustomEditor(typeof(LuaEntity))]
    public class LuaEntityInspector : UnityEditor.Editor
    {
        delegate bool PropertyDrawer(string propertyName, object value, out object nvalue);

        static Dictionary<string, Dictionary<int, bool>> poolComponentState = new Dictionary<string, Dictionary<int, bool>>();
        static GUIStyle foldoutStyle;
        static string componentNameSearchTerm = string.Empty;
        static Dictionary<Type, PropertyDrawer> propertyTypeDrawer = new Dictionary<Type, PropertyDrawer>();
        static PropertyDrawer defaultDrawer = null;

        static bool draw(string propertyName, object value, bool drawLuaTable, out object nvalue)
        {
            bool ret = false;
            if (value == null)
            {
                nvalue = null;
                EntitasEditorLayout.BeginHorizontal();
                {
                    EditorGUILayout.LabelField(propertyName, "null");
                    if (GUILayout.Button("CreateString", GUILayout.Height(14)))
                    {
                        nvalue = string.Empty;
                        ret = true;
                    }
                    if (GUILayout.Button("CreateNumber", GUILayout.Height(14)))
                    {
                        nvalue = 0d;
                        ret = true;
                    }
                }
                EntitasEditorLayout.EndHorizontal();
                return ret;
            }

            EntitasEditorLayout.BeginVertical();
            {
                PropertyDrawer drawer;
                if ((!drawLuaTable && value is LuaTable) ||
                    !propertyTypeDrawer.TryGetValue(value.GetType(), out drawer))
                    drawer = defaultDrawer;
                ret = drawer(propertyName, value, out nvalue);
            }
            EntitasEditorLayout.EndVertical();

            return ret;
        }

        static LuaEntityInspector()
        {
            foldoutStyle = new GUIStyle(EditorStyles.foldout);
            foldoutStyle.fontStyle = FontStyle.Bold;

            defaultDrawer = (string name, object value, out object nvalue) =>
            {
                nvalue = value;
                EditorGUILayout.LabelField(name, value.ToString());
                return false;
            };

            propertyTypeDrawer[typeof(double)] = (string name, object value, out object nvalue) =>
            {
                EntitasEditorLayout.BeginHorizontal();

                nvalue = EditorGUILayout.DoubleField(name, (double)value);
                if (GUILayout.Button("str", GUILayout.Width(35), GUILayout.Height(14)))
                {
                    EntitasEditorLayout.EndHorizontal();
                    nvalue = nvalue.ToString();
                    return true;
                }

                EntitasEditorLayout.EndHorizontal();
                return Math.Abs((double)value - (double)nvalue) > Mathf.Epsilon;
            };
            propertyTypeDrawer[typeof(string)] = (string name, object value, out object nvalue) =>
            {
                EntitasEditorLayout.BeginHorizontal();

                nvalue = EditorGUILayout.TextField(name, (string)value);
                if (GUILayout.Button("num", GUILayout.Width(35), GUILayout.Height(14)))
                {
                    EntitasEditorLayout.EndHorizontal();
                    double tmp;
                    nvalue = double.TryParse(nvalue.ToString(), out tmp) ? tmp : 0d;
                    return true;
                }

                EntitasEditorLayout.EndHorizontal();
                return nvalue != value;
            };
            propertyTypeDrawer[typeof(LuaTable)] = (string name, object value, out object nvalue) =>
            {
                nvalue = value;
                LuaTable table = value as LuaTable;
                bool modify = false;

                using (var dict = table.ToDictTable())
                {
                    using (var e = dict.GetEnumerator())
                    {
                        while (e.MoveNext())
                        {
                            object tmp;
                            bool arrayKey = e.Current.Key is double;
                            if (draw(name + "." + (arrayKey ? "" : "'") + e.Current.Key + (arrayKey ? "" : "'"), e.Current.Value, false, out tmp))
                            {
                                if (arrayKey) table[Convert.ToInt32(e.Current.Key)] = tmp;
                                else table[e.Current.Key.ToString()] = tmp;
                                modify = true;
                            }
                        }
                    }
                }

                return modify;
            };
        }


        public override void OnInspectorGUI()
        {
            LuaEntity entity = target as LuaEntity;

            var bgColor = GUI.backgroundColor;
            GUI.backgroundColor = Color.red;
            if (GUILayout.Button("Destroy Entity"))
            {
                LuaEntity.DestroyEntity(entity.poolName, entity.entityId);
            }
            GUI.backgroundColor = bgColor;

            DrawComponents(entity.poolName, entity.entityId);

            EditorGUILayout.Space();

            EditorGUILayout.LabelField("Retained by (" + LuaEntity.GetEntityRetainCount(entity.poolName, entity.entityId) + ")", EditorStyles.boldLabel);

            EntitasEditorLayout.BeginVerticalBox();
            {
                string[] owners = LuaEntity.GetEntityOwners(entity.poolName, entity.entityId);
                foreach (var owner in owners)
                {
                    EditorGUILayout.LabelField(owner);
                }
            }
            EntitasEditorLayout.EndVertical();
        }


        void DrawComponents(string poolName, int entityId)
        {
            Dictionary<int, bool> componentState;
            if (!poolComponentState.TryGetValue(poolName, out componentState))
            {
                componentState = new Dictionary<int, bool>();
                poolComponentState.Add(poolName, componentState);
            }

            int[] componentTypeIds = LuaEntity.GetEntityComponentIds(poolName, entityId);

            EntitasEditorLayout.BeginVerticalBox();
            {
                EntitasEditorLayout.BeginHorizontal();
                {
                    bool forceSet = false, state = false;
                    EditorGUILayout.LabelField("Components (" + componentTypeIds.Length + ")", EditorStyles.boldLabel);
                    if (GUILayout.Button("▸", GUILayout.Width(21), GUILayout.Height(14)))
                    {
                        forceSet = true;
                        state = false;
                    }
                    if (GUILayout.Button("▾", GUILayout.Width(21), GUILayout.Height(14)))
                    {
                        forceSet = true;
                        state = true;
                    }

                    for (int i = 0; i < componentTypeIds.Length; i++)
                    {
                        if (forceSet || !componentState.ContainsKey(componentTypeIds[i]))
                        {
                            componentState[componentTypeIds[i]] = state;
                        }
                    }
                }
                EntitasEditorLayout.EndHorizontal();

                EditorGUILayout.Space();

                var index = EditorGUILayout.Popup("Add Component", -1, LuaEntity.GetComponentSelectText());
                if (index >= 0)
                {
                    int componentId = LuaEntity.GetComponentIdByIndex(index);
                    LuaEntity.AddComponent(poolName, entityId, componentId);
                }

                EditorGUILayout.Space();

                EntitasEditorLayout.BeginHorizontal();
                {
                    componentNameSearchTerm = EditorGUILayout.TextField("Search", componentNameSearchTerm);

                    const string clearButtonControlName = "Clear Button";
                    GUI.SetNextControlName(clearButtonControlName);
                    if (GUILayout.Button("x", GUILayout.Width(19), GUILayout.Height(14)))
                    {
                        componentNameSearchTerm = string.Empty;
                        GUI.FocusControl(clearButtonControlName);
                    }
                }
                EntitasEditorLayout.EndHorizontal();

                EditorGUILayout.Space();

                for (int i = 0; i < componentTypeIds.Length; i++)
                {
                    DrawComponent(poolName, entityId, componentTypeIds[i], componentState);
                }
            }
            EntitasEditorLayout.EndVertical();
        }


        void DrawComponent(string poolName, int entityId, int componentId, Dictionary<int, bool> state)
        {
            LuaEntity.ComponentStruct componentStruct = LuaEntity.GetComponentStruct(componentId);

            if (componentStruct.fullName.ToLower().Contains(componentNameSearchTerm.ToLower()))
            {
                var boxStyle = getColoredBoxStyle(LuaEntity.GetComponentSelectText().Length, componentStruct.id);
                EntitasEditorLayout.BeginVerticalBox(boxStyle);
                {
                    EntitasEditorLayout.BeginHorizontal();
                    {
                        if (componentStruct.propertyNames.Length == 0)
                        {
                            EditorGUILayout.LabelField(componentStruct.fullName, EditorStyles.boldLabel);
                        }
                        else
                        {
                            state[componentId] = EditorGUILayout.Foldout(state[componentId], componentStruct.fullName, foldoutStyle);
                        }
                        if (GUILayout.Button("-", GUILayout.Width(19), GUILayout.Height(14)))
                        {
                            LuaEntity.RemoveComponent(poolName, entityId, componentId);
                        }
                    }
                    EntitasEditorLayout.EndHorizontal();

                    if (state[componentId])
                    {
                        foreach (var propertyName in componentStruct.propertyNames)
                        {
                            DrawAndSetElement(poolName, entityId, componentId, propertyName);
                        }
                    }
                }
                EntitasEditorLayout.EndVertical();
            }
        }

        void DrawAndSetElement(string poolName, int entityId, int componentId, string propertyName)
        {
            object value = LuaEntity.GetEntityComponetnPropertyValue(poolName, entityId, componentId, propertyName);

            EntitasEditorLayout.BeginHorizontal();
            {
                object nvalue;
                if (draw(propertyName, value, true, out nvalue))
                {
                    LuaEntity.SetEntityComponetnPropertyValue(poolName, entityId, componentId, propertyName, nvalue);
                }
            }
            EntitasEditorLayout.EndHorizontal();
        }


        static Dictionary<int, GUIStyle> styles = new Dictionary<int, GUIStyle>();
        static GUIStyle getColoredBoxStyle(int totalComponents, int index)
        {
            int total = totalComponents > 30 ? 30 : totalComponents;
            index = index % 30;
            GUIStyle style;
            if (!styles.TryGetValue(index, out style))
            {
                float hue = index / (float)total;
                var componentColor = Color.HSVToRGB(hue, 0.7f, 1f);
                componentColor.a = 0.15f;
                style = new GUIStyle(GUI.skin.box);
                style.normal.background = createTexture(2, 2, componentColor);
                styles[index] = style;
            }
            return style;
        }

        static Texture2D createTexture(int width, int height, Color color)
        {
            var pixels = new Color[width * height];
            for (int i = 0; i < pixels.Length; ++i)
            {
                pixels[i] = color;
            }
            var result = new Texture2D(width, height);
            result.SetPixels(pixels);
            result.Apply();
            return result;
        }
    }
}
