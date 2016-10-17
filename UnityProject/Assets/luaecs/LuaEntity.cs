using UnityEngine;
using LuaInterface;
using System.Collections.Generic;
using System.Text;

namespace SuperMobs.Game.Lua
{
    public class LuaEntity : MonoBehaviour
    {
        public static void RegToLua(LuaState l)
        {
            l.LuaPushFunction(L =>
            {
                object[] componentNames = l.GetTable("ecs.component.allcomponentnames").ToArray();
                object[] propertyNameArrs = l.GetTable("ecs.component.allcomponentpropertys").ToArray();
                List<string> componentSelectTextsList = new List<string>();
                for (int i = 1; i <= componentNames.Length; i++)
                {
                    ComponentStruct cstruct = new ComponentStruct();
                    cstruct.fullName = componentNames[i - 1].ToString();
                    cstruct.name = cstruct.fullName.Substring(cstruct.fullName.LastIndexOf('.') + 1);
                    cstruct.id = i;

                    object[] pnames = (propertyNameArrs[i - 1] as LuaTable).ToArray();
                    cstruct.propertyNames = new string[pnames.Length];
                    for (int j = 0; j < pnames.Length; j++)
                        cstruct.propertyNames[j] = pnames[j].ToString();

                    componentSelectTextsList.Add(cstruct.fullName.Replace(".", "/"));
                    componentSelectIds.Add(i);
                    componentStructs.Add(cstruct);
                }
                componentSelectTexts = componentSelectTextsList.ToArray();

                getEntityComponentIds = l.GetFunction("ecs.bridge.getentitycomponentids");
                getEntityComponetnPropertyValue = l.GetFunction("ecs.bridge.getentitycomponetnpropertyvalue");
                setEntityComponetnPropertyValue = l.GetFunction("ecs.bridge.setentitycomponetnpropertyvalue");
                addComponent = l.GetFunction("ecs.bridge.addcomponent");
                removeComponent = l.GetFunction("ecs.bridge.removecomponent");
                getEntityOwners = l.GetFunction("ecs.bridge.getentityowners");
                getEntityRetainCount = l.GetFunction("ecs.bridge.getentityretaincount");
                isMatch = l.GetFunction("ecs.bridge.ismatch");
                destroyEntity = l.GetFunction("ecs.bridge.destroyentity");
                return 0;
            });
            l.LuaSetGlobal("ECS_INIT_EDITOR_ENTITY");

            l.LuaPushFunction(L =>
            {
                LuaEntity entity = new GameObject().AddComponent<LuaEntity>();
                entity.poolName = ToLua.CheckString(L, 1);
                entity.entityId = System.Convert.ToInt32(LuaDLL.luaL_checknumber(L, 2));
                entity.transform.parent = LuaPool.Get(entity.poolName).transform;
                entity.name = "Entity_" + entity.entityId;
                entity.gameObject.hideFlags = HideFlags.HideInHierarchy;

                if (!entities.ContainsKey(entity.poolName))
                    entities.Add(entity.poolName, new Dictionary<int, LuaEntity>());
                entities[entity.poolName].Add(entity.entityId, entity);

                return 0;
            });
            l.LuaSetGlobal("ECS_POOL_ONENTITYCREATE");

            l.LuaPushFunction(L =>
            {
                string poolName = ToLua.CheckString(L, 1);
                int id = System.Convert.ToInt32(LuaDLL.luaL_checknumber(L, 2));
                Destroy(entities[poolName][id].gameObject);
                entities[poolName].Remove(id);
                return 0;
            });
            l.LuaSetGlobal("ECS_POOL_ONENTITYDESTROY");
        }


        public struct ComponentStruct
        {
            public string fullName;
            public string name;
            public int id;
            public string[] propertyNames;
        }
        private static string[] componentSelectTexts = null;
        private static List<int> componentSelectIds = new List<int>();
        private static List<ComponentStruct> componentStructs = new List<ComponentStruct>();

        public static string[] GetComponentSelectText() { return componentSelectTexts; }
        public static int GetComponentIdByIndex(int i) { return i + 1; }

        private static Dictionary<string, Dictionary<int, LuaEntity>> entities = new Dictionary<string, Dictionary<int, LuaEntity>>();
        private static LuaFunction getEntityComponentIds = null;
        private static LuaFunction getEntityComponetnPropertyValue = null;
        private static LuaFunction setEntityComponetnPropertyValue = null;
        private static LuaFunction addComponent = null;
        private static LuaFunction removeComponent = null;
        private static LuaFunction getEntityOwners = null;
        private static LuaFunction getEntityRetainCount = null;
        private static LuaFunction isMatch = null;
        private static LuaFunction destroyEntity = null;

        public static ComponentStruct GetComponentStruct(int componentId) { return componentStructs[componentId - 1]; }

        public static int[] GetEntityComponentIds(string poolName, int id)
        {
            getEntityComponentIds.BeginPCall();
            getEntityComponentIds.Push(poolName);
            getEntityComponentIds.Push(id);
            getEntityComponentIds.PCall();

            int count = System.Convert.ToInt32(getEntityComponentIds.CheckNumber());
            int[] ret = new int[count];
            for (int i = 0; i < count; i++)
                ret[i] = System.Convert.ToInt32(getEntityComponentIds.CheckNumber());

            getEntityComponentIds.EndPCall();
            return ret;
        }

        public static object GetEntityComponetnPropertyValue(string poolName, int entityid, int componentId, string propertyName)
        {
            getEntityComponetnPropertyValue.BeginPCall();
            getEntityComponetnPropertyValue.Push(poolName);
            getEntityComponetnPropertyValue.Push(entityid);
            getEntityComponetnPropertyValue.Push(componentId);
            getEntityComponetnPropertyValue.Push(propertyName);
            getEntityComponetnPropertyValue.PCall();
            object value = getEntityComponetnPropertyValue.CheckVariant();
            getEntityComponetnPropertyValue.EndPCall();
            return value;
        }

        public static void SetEntityComponetnPropertyValue(string poolName, int entityid, int componentId, string propertyName, object value)
        {
            setEntityComponetnPropertyValue.BeginPCall();
            setEntityComponetnPropertyValue.Push(poolName);
            setEntityComponetnPropertyValue.Push(entityid);
            setEntityComponetnPropertyValue.Push(componentId);
            setEntityComponetnPropertyValue.Push(propertyName);
            setEntityComponetnPropertyValue.Push(value);
            setEntityComponetnPropertyValue.PCall();
            setEntityComponetnPropertyValue.EndPCall();
        }

        public static void AddComponent(string poolName, int entityid, int componentId)
        {
            addComponent.BeginPCall();
            addComponent.Push(poolName);
            addComponent.Push(entityid);
            addComponent.Push(componentId);
            addComponent.PCall();
            addComponent.EndPCall();
        }

        public static void RemoveComponent(string poolName, int entityid, int componentId)
        {
            removeComponent.BeginPCall();
            removeComponent.Push(poolName);
            removeComponent.Push(entityid);
            removeComponent.Push(componentId);
            removeComponent.PCall();
            removeComponent.EndPCall();
        }

        public static string[] GetEntityOwners(string poolName, int entityId)
        {
            getEntityOwners.BeginPCall();
            getEntityOwners.Push(poolName);
            getEntityOwners.Push(entityId);
            getEntityOwners.PCall();

            int count = System.Convert.ToInt32(getEntityOwners.CheckNumber());
            string[] ret = new string[count];
            for (int i = 0; i < count; i++)
                ret[i] = getEntityOwners.CheckString();

            getEntityOwners.EndPCall();
            return ret;
        }

        public static int GetEntityRetainCount(string poolName, int entityId)
        {
            getEntityRetainCount.BeginPCall();
            getEntityRetainCount.Push(poolName);
            getEntityRetainCount.Push(entityId);
            getEntityRetainCount.PCall();
            int count = System.Convert.ToInt32(getEntityRetainCount.CheckNumber());
            getEntityRetainCount.EndPCall();
            return count;
        }

        public static void DestroyEntity(string poolName, int entityId)
        {
            destroyEntity.BeginPCall();
            destroyEntity.Push(poolName);
            destroyEntity.Push(entityId);
            destroyEntity.PCall();
            destroyEntity.EndPCall();
        }



        public int entityId;
        public string poolName;

        void Update()
        {
            StringBuilder sb = new StringBuilder()
                .Append("Entity_")
                .Append(entityId)
                .Append("(*")
                .Append(GetEntityRetainCount(poolName, entityId))
                .Append(")")
                .Append("(");

            int[] componentIds = GetEntityComponentIds(poolName, entityId);
            for (int i = 0; i < componentIds.Length; i++)
            {
                if (i != 0)
                    sb.Append(",");
                sb.Append(GetComponentStruct(componentIds[i]).name);
            }
            sb.Append(")");
            name = sb.ToString();

            bool hidden = true;
            List<int> ids = LuaPool.Get(poolName).entityDisplayMatcherIds;
            if (ids.Count == 0)
            {
                hidden = false;
            }
            else
            {
                foreach (int matcherId in ids)
                {
                    isMatch.BeginPCall();
                    isMatch.Push(poolName);
                    isMatch.Push(entityId);
                    isMatch.Push(matcherId);
                    isMatch.PCall();
                    hidden = !isMatch.CheckBoolean();
                    isMatch.EndPCall();

                    if (!hidden)
                        break;
                }
            }

            gameObject.hideFlags = hidden ? HideFlags.HideInHierarchy : HideFlags.None;
        }
    }
}