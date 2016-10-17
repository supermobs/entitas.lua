using UnityEngine;
using LuaInterface;
using System.Collections.Generic;

namespace SuperMobs.Game.Lua
{
    public class LuaPool : MonoBehaviour
    {
        public static void RegToLua(LuaState l)
        {
            l.LuaPushFunction(L =>
            {
                getEntitiesCount = l.GetFunction("ecs.bridge.getentitiescount");
                createEntity = l.GetFunction("ecs.bridge.createentity");
                destroyAllEntities = l.GetFunction("ecs.bridge.destroyallentities");
                getGroupinfo = l.GetFunction("ecs.bridge.getgroupinfo");
                return 0;
            });
            l.LuaSetGlobal("ECS_INIT_EDITOR_POOL");

            l.LuaPushFunction(L =>
            {
                LuaPool luaPool = new GameObject().AddComponent<LuaPool>();
                luaPool.poolName = ToLua.CheckString(L, 1);
                pools.Add(luaPool.poolName, luaPool);
                
                return 0;
            });
            l.LuaSetGlobal("ECS_POOL_ONCREATE");
        }

        private static Dictionary<string, LuaPool> pools = new Dictionary<string, LuaPool>();
        private static Dictionary<string, LuaDictTable> groupInfos = new Dictionary<string, LuaDictTable>();
        private static LuaFunction getEntitiesCount = null;
        private static LuaFunction createEntity = null;
        private static LuaFunction destroyAllEntities = null;
        private static LuaFunction getGroupinfo = null;

        public static LuaPool Get(string poolName)
        {
            return pools[poolName];
        }

        public static void GetEntitiesCount(string poolName, out int total, out int reusable, out int retained)
        {
            getEntitiesCount.BeginPCall();
            getEntitiesCount.Push(poolName);
            getEntitiesCount.PCall();

            total = System.Convert.ToInt32(getEntitiesCount.CheckNumber());
            reusable = System.Convert.ToInt32(getEntitiesCount.CheckNumber());
            retained = System.Convert.ToInt32(getEntitiesCount.CheckNumber());

            getEntitiesCount.EndPCall();
        }

        public static void CreateEntity(string poolName)
        {
            createEntity.BeginPCall();
            createEntity.Push(poolName);
            createEntity.PCall();
            createEntity.EndPCall();
        }

        public static void DestroyAllEntity(string poolName)
        {
            destroyAllEntities.BeginPCall();
            destroyAllEntities.Push(poolName);
            destroyAllEntities.PCall();
            destroyAllEntities.EndPCall();
        }

        public static LuaDictTable GetGroupsInfo(string poolName)
        {
            if (!groupInfos.ContainsKey(poolName))
            {
                getGroupinfo.BeginPCall();
                getGroupinfo.Push(poolName);
                getGroupinfo.PCall();
                groupInfos[poolName] = getGroupinfo.CheckLuaTable().ToDictTable();
                getGroupinfo.EndPCall();
            }

            return groupInfos[poolName];
        }



        public string poolName;
        public List<int> entityDisplayMatcherIds = new List<int>();

        void Update()
        {
            int totalCount, reusableCount, retainedCount;
            GetEntitiesCount(poolName, out totalCount, out reusableCount, out retainedCount);
            name = (entityDisplayMatcherIds.Count > 0 ? "(*)" : "") + poolName + " (" +
                (totalCount - reusableCount - retainedCount) + " entities, " +
                reusableCount + " reusable, " + retainedCount + " retained)";
        }
    }
}