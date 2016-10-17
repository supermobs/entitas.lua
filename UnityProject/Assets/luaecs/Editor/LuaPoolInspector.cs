using Entitas.Unity;
using LuaInterface;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace SuperMobs.Game.Lua.Editor
{
    [CustomEditor(typeof(LuaPool))]
    public class LuaPoolInspactor : UnityEditor.Editor
    {
        bool sortGroups = false;

        public override void OnInspectorGUI()
        {
            LuaPool pool = target as LuaPool;
            string poolName = pool.poolName;

            EntitasEditorLayout.BeginVerticalBox();
            {
                int totalCount, reusableCount, retainedCount;
                LuaPool.GetEntitiesCount(poolName, out totalCount, out reusableCount, out retainedCount);

                EditorGUILayout.LabelField(poolName, EditorStyles.boldLabel);
                EditorGUILayout.LabelField("Entities", (totalCount - reusableCount - retainedCount).ToString());
                EditorGUILayout.LabelField("Reusable entities", reusableCount.ToString());

                if (retainedCount != 0)
                {
                    var c = GUI.contentColor;
                    GUI.color = Color.red;
                    EditorGUILayout.LabelField("Retained entities", retainedCount.ToString());
                    GUI.color = c;
                    EditorGUILayout.HelpBox("WARNING: There are retained entities.\nDid you call entity.Retain(owner) and forgot to call entity.Release(owner)?", MessageType.Warning);
                }
                else
                {
                    EditorGUILayout.LabelField("Retained entities", retainedCount.ToString());
                }

                EntitasEditorLayout.BeginHorizontal();
                {
                    if (GUILayout.Button("Create Entity"))
                    {
                        LuaPool.CreateEntity(poolName);
                    }

                    var bgColor = GUI.backgroundColor;
                    GUI.backgroundColor = Color.red;
                    if (GUILayout.Button("Destroy All Entities"))
                    {
                        LuaPool.DestroyAllEntity(poolName);
                    }
                    GUI.backgroundColor = bgColor;
                }
                EntitasEditorLayout.EndHorizontal();
            }
            EntitasEditorLayout.EndVertical();

            Dictionary<string, KeyValuePair<int, int>> groupsInfo = new Dictionary<string, KeyValuePair<int, int>>();
            using (var enumerator = LuaPool.GetGroupsInfo(poolName).GetEnumerator())
            {
                while ((enumerator.MoveNext()))
                {
                    LuaTable info = enumerator.Current.Value as LuaTable;
                    groupsInfo.Add(info["desc"].ToString(), new KeyValuePair<int, int>(
                        System.Convert.ToInt32(((LuaTable)info["matcher"])["id"]),
                        System.Convert.ToInt32(((LuaTable)info["entities"])["count"])));
                }
            }

            if (groupsInfo.Count > 0)
            {
                EntitasEditorLayout.BeginVerticalBox();
                {
                    EntitasEditorLayout.BeginHorizontal();
                    {
                        EditorGUILayout.LabelField("Groups (" + groupsInfo.Count + ")", EditorStyles.boldLabel, GUILayout.Width(100));
                        EditorGUILayout.LabelField("sort", GUILayout.Width(30));
                        sortGroups = EditorGUILayout.Toggle(sortGroups);
                        if (pool.entityDisplayMatcherIds.Count > 0 && GUILayout.Button("clean filter", GUILayout.Width(100)))
                        {
                            pool.entityDisplayMatcherIds.Clear();
                        }
                    }
                    EntitasEditorLayout.EndHorizontal();

                    var groupList = sortGroups ? groupsInfo.OrderByDescending(p => p.Value.Value) : groupsInfo.OrderByDescending(p => p.Key);
                    foreach (var group in groupList)
                    {
                        EntitasEditorLayout.BeginHorizontal();
                        {
                            EditorGUILayout.LabelField(group.Key);
                            EditorGUILayout.LabelField(group.Value.Value.ToString(), GUILayout.Width(48));
                            bool pointOut = pool.entityDisplayMatcherIds.Contains(group.Value.Key);
                            bool nPointOut = EditorGUILayout.Toggle(pointOut, GUILayout.Width(48));
                            if (pointOut && !nPointOut)
                            {
                                pool.entityDisplayMatcherIds.Remove(group.Value.Key);
                            }
                            if (!pointOut && nPointOut)
                            {
                                pool.entityDisplayMatcherIds.Add(group.Value.Key);
                            }
                        }
                        EntitasEditorLayout.EndHorizontal();
                    }
                }
                EntitasEditorLayout.EndVertical();
            }

            EditorUtility.SetDirty(target);
        }

    }
}
