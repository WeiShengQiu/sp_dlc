-------------------------------------------------
-- FrontEnd
-------------------------------------------------
local bIsBNW = ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY);
local bIsSP  = false;
for row in DB.Query("SELECT * from UnitPromotions Where Type = 'PROMOTION_CORPS_1' LIMIT 1") do
	if row then
		bIsSP = true;
	end
end

function ShowHideHandler( bIsHide, bIsInit )

	-- Check for game invites first.  If we have a game invite, we will have flipped 
	-- the Civ5App::eHasShownLegal and not show the legal/touch screens.
	UI:CheckForCommandLineInvitation();
	
	if( not UI:HasShownLegal() ) then
		UIManager:QueuePopup( Controls.LegalScreen, PopupPriority.LegalScreen );
	end
	
	if( not bIsInit ) then
		Controls.AtlasLogo:UnloadTexture();
		Controls.Timer:Stop();
	end
	
	if( not bIsHide ) then
		Controls.FadeIn:SetToEnd();
	--	Controls.AtlasLogo:SetTexture( "CivilzationVAtlas.dds" );
		SetAtlasLogo();
		
		UIManager:SetUICursor( 0 );
		UIManager:QueuePopup( Controls.MainMenu, PopupPriority.MainMenu );
	else
		Controls.AtlasLogo:UnloadTexture();
	end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

local screenX, screenY = UIManager:GetScreenSizeVal()
function SetAtlasLogo()
	local AtlasTexture;
	
	if (bIsSP) then
		-- SP logo are SP_Logo_1.dds & SP_Logo_2.dds | SP images are SP_Atlas_0.dds to SP_Atlas_9.dds
		Controls.SPVersion:SetText(Locale.ConvertTextKey("TXT_KEY_SP_VERSION") or "");
		Controls.SPLogo:SetTextureAndResize( string.format("SP_Logo_%d.dds", math.random(2)) );
		AtlasTexture = string.format("SP_Atlas_%d.dds", math.random(0, 9));
	elseif (math.random(2) == 1) then
		-- Vanilla images are loadingbasegame_1.dds to loadingbasegame_20.dds
		AtlasTexture = string.format("loadingbasegame_%d.dds", math.random(20));
	else
	    if (bIsBNW) then
		-- BNW images are loading_1.dds to loading_24.dds
		AtlasTexture = string.format("loading_%d.dds", math.random(24));
	    else
		-- G&K images are loading_1.dds to loading_11.dds and loading_13.dds to loading_19.dds
		local pic = math.random(2,19); if (pic == 12) then pic = 1 end
		AtlasTexture = string.format("loading_%d.dds", pic);
	    end
	end
	Controls.SPLogo:SetHide(not bIsSP);
	Controls.AtlasLogo:SetTextureAndResize( AtlasTexture or "CivilzationVAtlas.dds" );
	local x, y = Controls.AtlasLogo:GetSizeVal();
	local k = math.max( screenX/x, screenY/y );
	Controls.AtlasLogo:Resize( x*k, y*k );
end
function SetRandomAtlasLogo()
	--Controls.AtlasLogo:UnloadTexture();
	if ContextPtr:IsHidden() then
		Controls.Timer:Stop();
	else
		Controls.Timer:SetToBeginning();
		Controls.Timer:Play();
		Controls.FadeIn:SetToBeginning();
		Controls.FadeIn:Play();
		return SetAtlasLogo();
	end
end
Controls.Timer:RegisterAnimCallback( SetRandomAtlasLogo )
Controls.Button:RegisterCallback( Mouse.eLClick, SetRandomAtlasLogo )
