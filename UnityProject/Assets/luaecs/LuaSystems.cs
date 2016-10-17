using UnityEngine;
using LuaInterface;
using System.Collections.Generic;
using System;

namespace SuperMobs.Game.Lua
{
    public enum AvgResetInterval
    {
        Always = 1,
        VeryFast = 30,
        Fast = 60,
        Normal = 120,
        Slow = 300,
        Never = int.MaxValue
    }

    public class LuaSystems : MonoBehaviour
    {
        public static void RegToLua(LuaState l)
        {
            l.LuaPushFunction(L =>
            {
                profileTable = l.GetTable("ecs.debugsystems.profile");
                step = l.GetFunction("ecs.bridge.step");
                reset = l.GetFunction("ecs.bridge.reset");
                getSystemsInitializeChild = l.GetFunction("ecs.bridge.getsystemsinitializechildren");
                getSystemsExecuteChild = l.GetFunction("ecs.bridge.getsystemsexecutechildren");
                isreactive = l.GetFunction("ecs.bridge.isreactive");
                return 0;
            });
            l.LuaSetGlobal("ECS_INIT_EDITOR_SYSTEMS");

            l.LuaPushFunction(L =>
            {
                LuaSystems luaSystems = new GameObject().AddComponent<LuaSystems>();
                luaSystems.systemsName = ToLua.CheckString(L, 1);
                luaSystemsObjs.Add(luaSystems.systemsName, luaSystems);

                return 0;
            });
            l.LuaSetGlobal("ECS_DEBUGSYSTEMS_ONCREATE");

            l.LuaPushFunction(L =>
            {
                string systemsName = ToLua.CheckString(L, 1);
                string parentName = ToLua.CheckString(L, 2);
                if (!luaSystemsObjs.ContainsKey(parentName) || !luaSystemsObjs.ContainsKey(systemsName))
                {
                    Debug.LogError("systems do not exist when DEBUGSYSTEMS_ONPARENT, parent = " + parentName + ", child = " + systemsName);
                }
                else
                {
                    luaSystemsObjs[systemsName].transform.parent = luaSystemsObjs[parentName].transform;
                }

                return 0;
            });
            l.LuaSetGlobal("ECS_DEBUGSYSTEMS_ONPARENT");
        }

        private static LuaTable profileTable = null;
        private static LuaFunction step = null;
        private static LuaFunction reset = null;
        private static LuaFunction getSystemsInitializeChild = null;
        private static LuaFunction getSystemsExecuteChild = null;
        private static LuaFunction isreactive = null;
        private static Dictionary<string, LuaSystems> luaSystemsObjs = new Dictionary<string, LuaSystems>();

        public static bool IsReactive(string name)
        {
            isreactive.BeginPCall();
            isreactive.Push(name);
            isreactive.PCall();
            bool ret = isreactive.CheckBoolean();
            isreactive.EndPCall();
            return ret;
        }

        public static void Step(string systemsName)
        {
            if (luaSystemsObjs[systemsName].stepState == StepState.Disable)
                luaSystemsObjs[systemsName].stepState = StepState.Enable;
        }

        public static bool IsSystems(string name)
        {
            return GetProfile(name)["initializesystemcount"] != null;
        }

        public static float GetAverageCost(string name)
        {
            LuaTable tab = GetProfile(name);
            int count = Convert.ToInt32(tab["executecount"]);
            return count > 0 ? Convert.ToSingle(tab["executecosttotal"]) / count : 0;
        }

        public static void Reset(string systemsName)
        {
            reset.BeginPCall();
            reset.Push(systemsName);
            reset.PCall();
            reset.EndPCall();
        }

        public static string[] GetInitializeChildNameList(string systemsName)
        {
            getSystemsInitializeChild.BeginPCall();
            getSystemsInitializeChild.Push(systemsName);
            getSystemsInitializeChild.PCall();
            object[] ret = getSystemsInitializeChild.CheckLuaTable().ToArray();
            getSystemsInitializeChild.EndPCall();

            string[] list = new string[ret.Length];
            for (int i = 0; i < ret.Length; i++)
                list[i] = (ret[i] as LuaTable)["name"].ToString();
            return list;

        }

        public static string[] GetExecuteChildNameList(string systemsName)
        {
            getSystemsExecuteChild.BeginPCall();
            getSystemsExecuteChild.Push(systemsName);
            getSystemsExecuteChild.PCall();
            object[] ret = getSystemsExecuteChild.CheckLuaTable().ToArray();
            getSystemsExecuteChild.EndPCall();

            string[] list = new string[ret.Length];
            for (int i = 0; i < ret.Length; i++)
                list[i] = (ret[i] as LuaTable)["name"].ToString();
            return list;
        }

        public static LuaTable GetProfile(string name) { return profileTable[name] as LuaTable; }


        public enum StepState { Disable, Enable, Over }

        public string systemsName;
        public StepState stepState;
        public AvgResetInterval avgResetInterval = AvgResetInterval.Never;
        private LuaTable profile;

        void Start()
        {
            profile = GetProfile(systemsName);
        }

        void Update()
        {
            if (stepState == StepState.Enable)
            {
                stepState = StepState.Over;
                step.BeginPCall();
                step.Push(systemsName);
                step.PCall();
                step.EndPCall();
            }

            name = string.Format("{0} ({1} init, {2} exe, {3:0.###} ms)",
                systemsName, profile["initializesystemcount"], profile["executesystemcount"], profile["executecostnow"]);

            if (Time.frameCount % (int)avgResetInterval == 0 && (bool)profile["enable"])
            {
                Reset(systemsName);
            }
        }

    }
}