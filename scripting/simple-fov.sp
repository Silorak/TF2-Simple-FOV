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
        if (fov > 0)
        {
            SetFov(client, fov);
            SetCookieInt(client, cookieFov, fov);
            return Plugin_Handled;
        }
    }

    ReplyToCommand(client, "%s Syntax: sm_fov <number|reset>", PLUGIN_PREFIX);
    return Plugin_Handled;
}

public OnPluginStart()
{
    RegConsoleCmd("sm_fov", CmdSetFov, "Set Field of View to a custom value");

    cookieFov     = RegClientCookie("cm_cookie_fov", "FOV", CookieAccess_Protected);

    CreateConVar("classicmovement_version", PLUGIN_VERSION, "Classic Movement FOV version", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    cm_fov_min = CreateConVar("fov_min", "90", "Minimum FOV a client can set with the !fov command", _, true, 90.0, true, 170.0);
    cm_fov_max = CreateConVar("fov_max", "170", "Minimum FOV a client can set with the !fov command", _, true, 90.0, true, 170.0);

    AutoExecConfig(true);

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
            SetupClient(i);

        if (AreClientCookiesCached(i))
            LoadCookies(i);
    }
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

// Main {{{
public OnPreThink(client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    new buttons = GetClientButtons(client);

    // Check if the fov was reset by zooming
    if (buttons & IN_ATTACK2 && GetEntProp(client, Prop_Send, "m_iFOV") == 0)
        UpdateFov(client);
}
// Setup, Variables, Misc, ... {{{
SetupClient(client)
{
    if (IsFakeClient(client) || client < 1 || client > MAXPLAYERS)
        return;

    SDKHook(client, SDKHook_PreThink, OnPreThink);
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
    int min = GetConVarInt(cm_fov_min);
    int max = GetConVarInt(cm_fov_max);

    if (fov > max) {
        ReplyToCommand(client, "\x04[SM] \x01Your FOV value is to big, %d is the limit.", max);
        return;
    } if (fov < min) {
        ReplyToCommand(client, "\x04[SM] \x01Your FOV value is to small, %d is the limit.", min);
        return;
    }

    if (max >= fov >= min)
    {
        SetEntProp(client, Prop_Send, "m_iFOV", fov);
        SetEntProp(client, Prop_Send, "m_iDefaultFOV", fov);
    } 
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
