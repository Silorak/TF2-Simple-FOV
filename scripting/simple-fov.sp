#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#pragma semicolon 1

// #define DEBUG
#define PLUGIN_VERSION "0.1"
#define PLUGIN_PREFIX "[FOV]"

// Variables
ConVar cm_fov_min,
cm_fov_max;
// Cookies
new Handle:cookieFov     = INVALID_HANDLE;

public Plugin:myinfo = {
    name            = "Classic Movements FOV",
    author          = "mphe",
    description     = "Stripped FOV from Classic Movement plugin",
    version         = PLUGIN_VERSION,
    url             = "https://github.com/mphe/TF2-ClassicMovement"
};

public OnPluginStart()
{
    RegConsoleCmd("sm_fov", CmdSetFov, "Set Field of View to a custom value");

    cookieFov     = RegClientCookie("cm_cookie_fov", "FOV", CookieAccess_Protected);

    CreateConVar("classicmovement_version", PLUGIN_VERSION, "Classic Movement FOV version", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    cm_fov_min = CreateConVar("fov_min", "75", "Minimum FOV a client can set with the !fov command", _, true, 75.0, true, 130.0);
    cm_fov_max = CreateConVar("fov_max", "130", "Maximum FOV a client can set with the !fov command", _, true, 75.0, true, 130.0);

    AutoExecConfig(true);

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
            SetupClient(i);

        if (AreClientCookiesCached(i))
            LoadCookies(i);
    }
}

// Commands {{{
public Action:CmdSetFov(client, args)
{
    if (args > 0)
    {
        new String:buf[7];
        GetCmdArg(1, buf, sizeof(buf));

        if (StrEqual(buf, "reset", false))
        {
            ReplyToCommand(client, "%s Reset takes effect after respawn", PLUGIN_PREFIX);
            SetCookieInt(client, cookieFov, 0);
            return Plugin_Handled;
        }

        new fov = StringToInt(buf);

        if (fov > GetConVarInt(cm_fov_max)) {
            ReplyToCommand(client, "\x04%s \x01Your FOV value is to big, %d is the highest.", PLUGIN_PREFIX, GetConVarInt(cm_fov_max));
            return Plugin_Handled;
        }

        if (fov < GetConVarInt(cm_fov_min)) {
            ReplyToCommand(client, "\x04%s \x01Your FOV value is to small, %d is the smallest.", PLUGIN_PREFIX, GetConVarInt(cm_fov_min));
            return Plugin_Handled;
        }

        if (fov > 0)
        {
            SetFov(client, fov);
            SetCookieInt(client, cookieFov, fov);
            ReplyToCommand(client, "\x04%s \x01Your FOV has been set to %d on this server.", PLUGIN_PREFIX, fov);
            return Plugin_Handled;
        }
    }

    ReplyToCommand(client, "%s Syntax: sm_fov <number|reset>", PLUGIN_PREFIX);
    return Plugin_Handled;
}

public OnClientPutInServer(client)
{
    SetupClient(client);
}

public OnClientCookiesCached(client)
{
    LoadCookies(client);
}

public OnSpawnPost(client)
{
    UpdateFov(client);
}
// Setup, Variables, Misc, ... {{{
SetupClient(client)
{
    if (IsFakeClient(client) || client < 1 || client > MAXPLAYERS)
        return;
        
    SDKHook(client, SDKHook_SpawnPost, OnSpawnPost);
}

LoadCookies(client)
{
    if (IsFakeClient(client) || client < 1 || client > MAXPLAYERS)
        return;

    if (IsClientInGame(client))
        UpdateFov(client);
}

SetFov(client, fov)
{
    if (fov < GetConVarInt(cm_fov_min) || fov > GetConVarInt(cm_fov_max)) {
        return;
    }
    SetEntProp(client, Prop_Send, "m_iFOV", fov);
    SetEntProp(client, Prop_Send, "m_iDefaultFOV", fov);
}

UpdateFov(client)
{
    SetFov(client, GetCookieInt(client, cookieFov, 0));
}

GetCookieInt(client, Handle:cookie, def)
{
    decl String:buf[12];
    GetClientCookie(client, cookie, buf, sizeof(buf));
    return StrEqual(buf, "") ? def : StringToInt(buf);
}

SetCookieInt(client, Handle:cookie, val)
{
    decl String:buf[12];
    IntToString(val, buf, sizeof(buf));
    SetClientCookie(client, cookie, buf);
}
