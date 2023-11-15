-------------------------------------------------
-- Game Loading Screen
-- modified by bc1 from 1.0.3.144 code
-------------------------------------------------
include( "PopulateUniques" )

local IconHookup = EUI.IconHookup
local CivIconHookup = EUI.CivIconHookup
local SimpleCivIconHookup = EUI.SimpleCivIconHookup
local InitializePopulateUniques = InitializePopulateUniques
local PopulateUniquesForGameLoad = PopulateUniquesForGameLoad

local g_civID = -1;
local g_isLoadComplete = false;

Controls.ProgressBar:SetPercent( 1 );

ContextPtr:SetShowHideHandler( 
function( isHide, isInit )
	if not isHide then
		UI.SetDontShowPopups(true);
		if not isInit then
			UIManager:SetUICursor( 1 );
			g_isLoadComplete = false;

			Controls.AlphaAnim:SetToBeginning();
			Controls.SlideAnim:SetToBeginning();
			Controls.ActivateButton:SetHide(true);

			-- Force some settings off when loading a HotSeat game.
			if not PreGame.IsMultiplayerGame() then
				PreGame.SetGameOption("GAMEOPTION_DYNAMIC_TURNS", false);
				PreGame.SetGameOption("GAMEOPTION_SIMULTANEOUS_TURNS", false);
				PreGame.SetGameOption("GAMEOPTION_PITBOSS", false);
			end

			-- Sets up Selected Civ Slot
			local civ = GameInfo.Civilizations[ PreGame.GetCivilization( Game:GetActivePlayer() ) ];
			if civ then
				g_civID = civ.ID;
				-- Use the Civilization_Leaders table to cross reference from this civ to the Leaders table
				local leader = GameInfo.Leaders[ GameInfo.Civilization_Leaders{ CivilizationType = civ.Type }().LeaderheadType ];

				-- Set Leader & Civ Text
				Controls.Civilization:LocalizeAndSetText( civ.Description );
				Controls.Leader:LocalizeAndSetText( leader.Description );
				-- Set Civ Leader Icon
-- there is no Portrait!!!	IconHookup( leader.PortraitIndex, 128, leader.IconAtlas, Controls.Portrait );

				-- Set Civ Icon
				SimpleCivIconHookup( Game.GetActivePlayer(), 80, Controls.IconShadow );

				-- Sets Trait bonus Text
				local trait = GameInfo.Traits[ GameInfo.Leader_Traits{ LeaderType = leader.Type }().TraitType ];
				Controls.BonusTitle:LocalizeAndSetText( trait.ShortDescription );
				Controls.BonusDescription:LocalizeAndSetText( trait.Description );

				-- Sets Bonus Icons
				InitializePopulateUniques();
				Controls.SubStack:DestroyAllChildren();
				PopulateUniquesForGameLoad( Controls.SubStack, civ.Type );

				-- Sets Dawn of Man Quote
				Controls.Quote:LocalizeAndSetText( civ.DawnOfManQuote or "" );

				-- Sets Dawn of Man Image
				Controls.Image:SetTexture(civ.DawnOfManImage);
				--print("civID: " .. g_civID);
				Controls.SlideAnim:ReprocessAnchoring();
			else
				g_civID = -1;
				PreGame.SetCivilization( 0, -1 );
			end
			if g_civID ~= -1 then
				Events.SerialEventDawnOfManShow(g_civID);
			end
		end
	elseif not isInit then
		UIManager:SetUICursor( 0 );
		Controls.Image:UnloadTexture();
		--print("Texture is unloaded");
		if g_civID ~= -1 then
			Events.SerialEventDawnOfManHide(g_civID);
		end
	end
end );
-------------
-- Start Game
-------------
local function OnActivateButtonClicked ()
	--print("Activate button clicked!");
	Events.LoadScreenClose();
	if not PreGame.IsMultiplayerGame() and not PreGame.IsHotSeatGame() then
		Game.SetPausePlayer( -1 );
	end
	
	UI.SetDontShowPopups( false );

	--UI.SetNextGameState( GameStates.MainGameView, g_iAIPlayer );
	
	-- Record Mode
	if PreGame.GetGameOption("GAMEOPTION_SP_RECORD_MODE") == 1 then
		-- Count Other MODs used
		local iOtherMODsCount = 0;
		for _, MOD in pairs(Modding.GetActivatedMods()) do
			if  MOD.ID ~= "f9b9c8aa-b6d1-4188-9239-c1de2207ab7c" -- SP - RWO
			and MOD.ID ~= "4e394966-aec9-4473-807f-0ddf8c1dddc1" -- TNL
			and MOD.ID ~= "d1b6328c-ff44-4b0d-aad7-c657f83610cd" -- DLL - VMC
			then
				iOtherMODsCount = iOtherMODsCount + 1
			end
		end
		local pPlayer = Players[Game.GetActivePlayer()]
		local iOMs = pPlayer:GetNumResourceTotal(GameInfoTypes["RESOURCE_OTHER_MODS"], false);
		if iOtherMODsCount > - iOMs then
			--Players[Game.GetActivePlayer()]:ChangeNumResourceTotal(GameInfoTypes["RESOURCE_OTHER_MODS"], iOMs - iOtherMODsCount);
			pPlayer:SendAndExecuteLuaFunction("CvLuaPlayer::lChangeNumResourceTotal", GameInfoTypes["RESOURCE_OTHER_MODS"], iOMs - iOtherMODsCount)
		end
		
		-- Count Game Load Times
		if UI:IsLoadedGame() then
			--Players[Game.GetActivePlayer()]:ChangeNumResourceTotal(GameInfoTypes["RESOURCE_LOAD"], - 1);
			pPlayer:SendAndExecuteLuaFunction("CvLuaPlayer::lChangeNumResourceTotal", GameInfoTypes["RESOURCE_LOAD"], -1)
		end
	end
end
Controls.ActivateButton:RegisterCallback( Mouse.eLClick, OnActivateButtonClicked );


----------------------
-- Key Down Processing
----------------------
ContextPtr:SetInputHandler(
function( uiMsg, wParam, lParam )
	if g_isLoadComplete
		and uiMsg == KeyEvents.KeyDown
		and ( wParam == Keys.VK_ESCAPE or wParam == Keys.VK_RETURN )
	then
		OnActivateButtonClicked();
	end
	return true;
end );

---------------------
-- Game Init complete
---------------------
Events.SequenceGameInitComplete.Add(
function()
	g_isLoadComplete = true;

	if PreGame.IsMultiplayerGame() or PreGame.IsHotSeatGame() then
		OnActivateButtonClicked();
	else
		Game.SetPausePlayer( Game.GetActivePlayer() );
		Controls.ActivateButtonText:LocalizeAndSetText( UI:IsLoadedGame() and "TXT_KEY_BEGIN_GAME_BUTTON_CONTINUE" or "TXT_KEY_BEGIN_GAME_BUTTON" );
		Controls.ActivateButton:SetHide(false);
		Controls.AlphaAnim:Play();
		Controls.SlideAnim:Play();
		UIManager:SetUICursor( 0 );
	end
end );
