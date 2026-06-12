# 📜 Syde Documentation

## Loading

```lua
local SydeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/yarrosvault/syde/refs/heads/main/source",true))()
```

## Loader (Optional But Somethings Will Not Be Available)

```lua
SydeUI:Load({
	Logo = '7488932274',
	Name = 'Lavender',
	Status = 'Stable', -- {Stable, Unstable, Detected, Patched}
	Accent = Color3.fromRGB(251, 144, 255), -- Window Accent Theme
	HitBox = Color3.fromRGB(251, 144, 255), -- Window HitBox Theme (ex. Toggle Color)
	AutoLoad = false, -- Does Not Work !
	Socials = {    -- Allows 1 Large and 2 Small Blocks
		{
			Name = 'Syde';
			Style = 'Discord';
			Size = "Large";
			CopyToClip = true -- Copy To Clip (coming very soon)
		},
		{
			Name = 'GitHub';
			Style = 'GitHub';
			Size = "Small";
			CopyToClip = true
		}
	},
	ConfigurationSaving = { -- Allows Config Saving
		Enabled = true,
		FolderName = 'since',
		FileName = "hot"
	},
	AutoJoinDiscord = { 
		Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
		Invite = "CZRZBwPz", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
		RememberJoins = false -- Set this to false to make them join the discord every time they load it up
	},
})
```

## Window

```lua
local Window = SydeUI:Init({
	Title = 'Lavender'; -- Set Title
	SubText = 'Made With 💓 By @SellEssence' -- Set Subtitle
})
```

## Creating A Tab

```lua
local a = Window:InitTab('Main') -- Icons Coming Very Soon
local b = Window:InitTab('AutoFarms')
local c = Window:InitTab('Fun')
local d = Window:InitTab('Esp')
local e = Window:InitTab('FE')
```

# 📌 Elements

```lua
SydeUI:Notify({
	Title = 'This is a Notification',
	Content = 'This is a Notification',
	Duration = 5
	-- Icons Coming Very Soon
	-- Types Coming Very Soon ex. {Options}
})
```

## Button

```lua
a:Button({
	Title = 'Button', -- Set Title
	Description = '', -- *Optional Description
	Type = 'Default', -- *Optional Type {Default, Hold}
	HoldTime = 2, -- Hold Time When Type is *Hold
	CallBack = function()
	       print('Clicked')
	end,
})
```

## Toggle

```lua
a:Toggle({
	Title = 'Toggle', -- Set Title
	Value = true, -- *Optional Default Value {true, false}
	Config = true, -- *Optional Config Window (Allows User To Set A KeyBind)
	CallBack = function(v)
		print(v)
	end,
})
```

