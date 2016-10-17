using UnityEngine;
using System.Collections;
using LuaInterface;
using SuperMobs.Game.Lua;
using System.IO;

public class ecseditor : MonoBehaviour
{
    LuaFunction func;
    LuaState lua;
    bool gameover = false;

    void Start()
    {
        lua = new LuaState();
        lua.Start();
        LuaBinder.Bind(lua);
        LuaSystems.RegToLua(lua);
        LuaPool.RegToLua(lua);
        LuaEntity.RegToLua(lua);

        lua.DoFile("main.lua");

        func = lua.GetFunction("UPDATE");
    }

    void Update()
    {
        if (gameover)
            return;
        func.BeginPCall();
        func.PCall();
        gameover = func.CheckBoolean();
        func.EndPCall();
    }

    void OnDestroy()
    {
        func.Dispose();
        func = null;

        lua.Dispose();
        lua = null;
    }
}
