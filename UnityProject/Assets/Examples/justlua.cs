using UnityEngine;
using System.Collections;
using LuaInterface;
using SuperMobs.Game.Lua;
using System.IO;

public class justlua : MonoBehaviour
{
    LuaState lua;

    void Start()
    {
        lua = new LuaState();
        lua.Start();
        
        lua.DoFile("test/main.lua");
    }

    void OnDestroy()
    {
        lua.Dispose();
        lua = null;
    }
}
