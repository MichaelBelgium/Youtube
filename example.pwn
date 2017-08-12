#include <a_samp>
#include <zcmd>
#include <sscanf2>
#include <[MV]_Youtube>

#define COLOR_RED	0xAA3333AA

new gYoutubeID[MAX_PLAYERS], gYoutubeIDForAll;
new gMyPlaylist[MAX_PLAYERS], gEveryonesPlaylist, gTotalPlaylists;

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Example filterscript to use with [MV]_Youtube");
	print("--------------------------------------\n");

	for(new i = 0; i < MAX_PLAYERS; i++) gYoutubeID[i] = INVALID_YT_ID;
	gYoutubeIDForAll = INVALID_YT_ID;

	gEveryonesPlaylist = CreatePlaylist("For All");
	gTotalPlaylists = 1;
	return 1;
}

public OnFilterScriptExit()
{
	RemovePlaylist(gEveryonesPlaylist);
	return 1;
}

public OnPlayerConnect(playerid)
{
	gMyPlaylist[playerid] = INVALID_PLAYLIST_ID;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(gMyPlaylist[playerid] != INVALID_PLAYLIST_ID) 
		RemovePlaylist(gMyPlaylist[playerid]);
	return 1;
}

// ============ PLAYLISTS ====================

CMD:createmyplaylist(playerid,params[])
{
	new name[32], string[128];
	if(gTotalPlaylists >= MAX_PLAYLISTS) return SendClientMessage(playerid, COLOR_RED, "Reached servers max playlists");
	if(gMyPlaylist[playerid] != INVALID_PLAYLIST_ID) return SendClientMessage(playerid, COLOR_RED, "You already made a playlist");
	if(sscanf(params, "s[32]", name)) return SendClientMessage(playerid, COLOR_RED, "Usage: /createmyplaylist [playlist name]");
	gMyPlaylist[playerid] = CreatePlaylist(name);
	gTotalPlaylists++;

	format(string, sizeof(string), "You created your own playlist \"%s\". Use /addtomyplaylist to add youtube songs", GetPlaylistName(gMyPlaylist[playerid]));
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:addtomyplaylist(playerid,params[])
{
	new song[256];
	if(gMyPlaylist[playerid] == INVALID_PLAYLIST_ID) return SendClientMessage(playerid, COLOR_RED, "You don't have a playlist");
	if(sscanf(params, "s[256]", song)) return SendClientMessage(playerid, COLOR_RED, "Usage: /addtomyplaylist [youtube url]");
	if(!IsValidYoutubeURL(song)) return SendClientMessage(playerid, COLOR_RED, "Invalid url.");

	PlayYoutubeVideoFor(song, playerid, gMyPlaylist[playerid]);
	return 1;
}

CMD:addtoglobalplaylist(playerid,params[])
{
	new song[256];
	if(sscanf(params, "s[256]", song)) return SendClientMessage(playerid, COLOR_RED, "Usage: /addtoglobalplaylist [youtube url]");
	if(!IsValidYoutubeURL(song)) return SendClientMessage(playerid, COLOR_RED, "Invalid url.");

	PlayYoutubeVideoFor(song, playerid, gEveryonesPlaylist);
	return 1;
}

// =========== NO PLAYLISTS ===============

CMD:playforme(playerid,params[])
{
	new song[256];
	if(sscanf(params, "s[256]", song)) return SendClientMessage(playerid, COLOR_RED, "Usage: /playforme [youtube url]");
	if(!IsValidYoutubeURL(song)) return SendClientMessage(playerid, COLOR_RED, "Invalid url.");
	if(IsYouTubeVideoPlaying(gYoutubeID[playerid])) return SendClientMessage(playerid, COLOR_RED, "A song is already playing.");

	gYoutubeID[playerid] = PlayYoutubeVideoFor(song, playerid);
	return 1;
}

CMD:playforall(playerid,params[])
{
	new song[256];
	if(sscanf(params, "s[256]", song)) return SendClientMessage(playerid, COLOR_RED, "Usage: /playforall [youtube url]");
	if(!IsValidYoutubeURL(song)) return SendClientMessage(playerid, COLOR_RED, "Invalid url.");
	if(IsYouTubeVideoPlaying(gYoutubeIDForAll)) return SendClientMessage(playerid, COLOR_RED, "A song is already playing.");

	gYoutubeIDForAll = PlayYoutubeVideoFor(song);
	return 1;
}	

CMD:whatsongisplayingforme(playerid,params[])
{
	new playing[256];

	format(playing, sizeof(playing), "Name: %s\nDuration: %i seconds\nLink: %s", GetVideoTitle(gYoutubeID[playerid]), GetVideoDuration(gYoutubeID[playerid]), GetVideoLink(gYoutubeID[playerid]));
	ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Now playing", playing, "OK", "");
	return 1;
}

CMD:whatsongisplaying(playerid,params[])
{
	new playing[256];

	format(playing, sizeof(playing), "Name: %s\nDuration: %i seconds\nLink: %s", GetVideoTitle(gYoutubeIDForAll), GetVideoDuration(gYoutubeIDForAll), GetVideoLink(gYoutubeIDForAll));
	ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Now playing", playing, "OK", "");
	return 1;
}

// ========================================

public OnYoutubeVideoStart(youtubeid)
{
	new string[256], time[3];
	
	formatSeconds(GetVideoDuration(youtubeid),time[0],time[1],time[2]);
	format(string,sizeof(string),"{0049FF}[Now playing] {00c9ff}%s (Duration: %02dh %02dm %02ds)",GetVideoTitle(youtubeid),time[0],time[1],time[2]);

	if(GetPlaylistFromVideo(youtubeid) != INVALID_PLAYLIST_ID)
		format(string, sizeof(string), "%s (Playlist: %s (%d))",string, GetPlaylistName(GetPlaylistFromVideo(youtubeid)), GetPlaylistFromVideo(youtubeid));

	if(GetVideoTarget(youtubeid) != INVALID_PLAYER_ID)
		SendClientMessage(GetVideoTarget(youtubeid), -1, string);
	else
		SendClientMessageToAll(-1, string);

	return 1;
}

public OnYoutubeVideoFinished(youtubeid)
{
	new string[128];
	if(youtubeid == gYoutubeIDForAll)
	{
		format(string, sizeof(string), "The song that played for everyone (%s) has finished. Execute /playforall to play another song.", GetVideoTitle(youtubeid));
		SendClientMessageToAll(-1, string);
	}
	else
	{
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++)
		{
			if(gYoutubeID[i] == youtubeid)
			{
				format(string, sizeof(string), "The song that played for you (%s) has finished. Execute /playforme to play another song.", GetVideoTitle(youtubeid));
				SendClientMessage(i, -1, string);
				break;
			}
		}
	}
	return 1;
}

public OnPlaylistFinished(playlistid)
{
	new string[128];
	if(playlistid == gYoutubeIDForAll)
	{
		format(string, sizeof(string), "{0049FF}[Playlist '%s'] {00c9ff}Finished. Type /addtoglobalplaylist to add songs to the playlist.",GetPlaylistName(playlistid));	
		SendClientMessageToAll(-1, string);
	}
	else
	{
		for(new i = 0, j = GetPlayerPoolSize(); i <= j; i++)
		{
			if(!IsPlayerConnected(i)) continue;
			if(gMyPlaylist[i] == playlistid)
			{
				format(string, sizeof(string), "{0049FF}[Playlist '%s'] {00c9ff}Finished. Type /addtomyplaylist to add songs to the playlist.",GetPlaylistName(playlistid));	
				SendClientMessage(i, -1, string);
				break;
			}
		}
	}
	return 1;
}

public OnYoutubeDownloadError(youtubeid, message[])
{
	new string[256], player = GetVideoTarget(youtubeid);

	format(string, sizeof(string), "An error has occured while downloading video %s: %s", GetVideoLink(youtubeid), message);
	
	if(player != INVALID_PLAYER_ID)
		SendClientMessage(player, COLOR_RED, string);
	else
		SendClientMessageToAll(COLOR_RED, string);
	return 1;
}

stock formatSeconds(seconds, &hours_left, &minutes_left, &seconds_left)
{
	hours_left = seconds/60/60;
	minutes_left = (seconds - hours_left*60*60)/60;
	seconds_left = (seconds - hours_left*60*60 - minutes_left*60);
}