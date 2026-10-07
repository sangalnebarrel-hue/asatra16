-- Secret dogs arriving on the tongue. Read by DogLineSpawner (server) and by the
-- SecretArrivals cinematic (every client).
--   Hold        seconds the dog waits on its stage (unbuyable) while its arrival plays;
--               the next spawn waits too. The arrival's whole act fits inside it.
--   Clips       authored DogAnimationClips played during the hold: {seconds, clip, looped}.
--               The dog switches to Walk when the hold ends.
--   SpeedScale  while this dog is on the tongue the whole tongue moves at this speed.
--   FreezeLine  the whole tongue stops (every dog on it idles) during the hold.
--   Whispers    the mysterious lines typed at the top of every screen, {seconds, text}.
--   Title       the reveal card once the arrival lands.
--   Color       the dog's signature colour for UI and FX.
--   Banner      the map-wide alert: {At, Style, Kicker, Title, Text, Hold}; false for none.
--               An arrival that times its own (ctx.ManualBanner) may still read it.
--   LateGrace   seconds late a client may still join it (default max(LateGrace, Hold*.6)).
local C = {}
C.Version = 1
-- Secrets arrive this many studs down the tongue from DogSpawn: right in the giant
-- head's mouth opening, where the yards can see them (DogSpawn is deep in the throat).
C.Stage = 18
-- Optional uploaded sound assets. 0 keeps the built-in synthesized cue.
C.Sounds = { Drone = 0, Heartbeat = 0, Impact = 0, Glitch = 0, Choir = 0, Chime = 0, Whoosh = 0, Sting = 0 }
-- A client that sees an arrival later than this (joined late, streamed in) skips it.
C.LateGrace = 3
-- Every player's camera is pulled to the arrival for its big moment (Studio and live).
-- Players with ReducedMotion, a busy camera or an open menu are never pulled.
C.Cutaway = true
-- The island at map scale, for the map-wide part of every arrival (studs, world space).
C.Map = {
	-- The yards and the tongue, where most players are.
	Center = Vector3.new(0, 1, 0),
	-- From Center to the yards' outer fences.
	Radius = 190,
	-- Altitude above Center for colossal things hung over the yards.
	Sky = 170,
	-- The tongue's stage, in the giant head's mouth.
	Mouth = Vector3.new(0, 2, -150),
	-- The giant head building (THE_DOG) the tongue comes out of, and a spot behind it where
	-- something colossal can rise and loom over it, seen from every yard.
	Head = Vector3.new(0, 60, -195),
	Backdrop = Vector3.new(0, 1, -420),
	-- The whole district (the far north holds the museum, lab and DOG-O-MATIC).
	Min = Vector3.new(-200, 0, -260),
	Max = Vector3.new(200, 0, 720),
	-- Real points on the island (DOGROTS_District.NavigationAnchors; the client takes the
	-- anchors' own positions once they stream in). Plaza, Museum, Lab and Machine are the
	-- older names of WelcomeHub, DogDex, MutationLab and the DOG-O-MATIC's prize stand.
	Landmarks = {
		WelcomeHub = Vector3.new(0, 3, 377), -- DistrictSpawn: where players join
		DogPark = Vector3.new(-100, 3, 238),
		Shops = Vector3.new(94, 3, 335),
		DogDex = Vector3.new(-64, 3, 465),
		MutationLab = Vector3.new(78, 3, 477),
		GlobalDigSite = Vector3.new(38, 3, 575),
		PortalRuins = Vector3.new(-63, 3, 564),
		Shelter = Vector3.new(105, 3, 177),
		PlayerYards = Vector3.new(0, 2, 110),
		-- The DOG-O-MATIC: its prize stand (CameraHooks.RewardSpawn) and the approach to it.
		RewardMachine = Vector3.new(-119, 1.2, 630),
		MachineApproach = Vector3.new(-76, 3, 630),
		Plaza = Vector3.new(0, 3, 377),
		Museum = Vector3.new(-64, 3, 465),
		Lab = Vector3.new(78, 3, 477),
		Machine = Vector3.new(-119, 1.2, 630),
	},
}

C.Dogs = {
	Cubedog = {
		-- Dogs/Cubedog: the map-wide act runs 7.2 s (PRE) before the stage act; the cube
		-- lands at 9.5, the flip at 10.4, the happy spin at 11.4.
		Hold = 12.7,
		FreezeLine = true,
		Clips = { { 0, "Idle", true }, { 9.5, "Impact" }, { 10.4, "Flip" }, { 11.4, "Happy" } },
		Whispers = { { 0.3, "something with six flat sides is coming." }, { 9.6, "every side of it is the front." } },
		Title = "CUBEDOG",
		Color = Color3.fromRGB(86, 214, 255),
		Banner = { At = 0.15, Style = "Glitch", Kicker = "■  SECRET DOG · SIX SIDES  ■", Text = "A PERFECT CUBE IS DRAWING ITSELF IN YOUR SKY", Hold = 3 },
	},
	Dogdogdogdog = {
		Hold = 6.6,
		Clips = { { 0, "Split" }, { 3.5, "Reassemble" }, { 5.6, "Happy", true } },
		Whispers = {
			{ 1.6, "dog dog dog dog dog dog dog dog" },
			{ 4.6, "there were eight. now there is one. now there are eight." },
		},
		Title = "DOGDOGDOGDOG",
		Color = Color3.fromRGB(255, 196, 64),
	},
	Spiderdog = {
		-- Dogs/Spiderdog: the stage act starts 9.2 s (STAGE) in; it lands at 12.05 and digs
		-- from 12.1 to 15.4.
		Hold = 15.4,
		FreezeLine = true,
		Clips = { { 0, "Run", true }, { 12.1, "Ability_MultiDig" } },
		Whispers = {
			{ 0.3, "you checked under the bed. you never checked the ceiling." },
			{ 12.2, "eight legs. zero questions." },
		},
		Title = "SPIDERDOG",
		Color = Color3.fromRGB(255, 120, 40),
		Banner = { At = 0.15, Style = "Horror", Kicker = "EIGHT LEGS · EIGHT EYES", Text = "THE LIGHTS ARE GOING OUT", Hold = 2.8 },
	},
	WrongDog = {
		-- Dogs/WrongDog: the island turns wrong first; the dog is on its stage from 5.4 (hidden
		-- before that and in the dark at 7.4-7.8, so no clip plays then), stares into every
		-- camera 7.8-11.0 and walks at Hold.
		Hold = 11.8,
		FreezeLine = true,
		Clips = { { 0, "EXP_Stare", true }, { 7.8, "UnstableEvent" }, { 11.0, "EXP_Unsettling", true } },
		Whispers = { { 5.8, "that is not how a dog is supposed to stand." }, { 8.0, "it is looking at you. only you." } },
		-- Shown by the module when every eye on the island opens (ctx.ManualBanner).
		Banner = {
			At = 1.9,
			Style = "Horror",
			Kicker = "⚠  SOMETHING IS WRONG  ⚠",
			Title = "IT IS LOOKING AT YOU",
			Text = "do not turn around.",
			Hold = 3.2,
		},
		Title = "THE WRONG DOG",
		Color = Color3.fromRGB(255, 40, 40),
	},
	NuclearPug = {
		-- Dogs/NuclearPug: the countdown runs 5 s (PRE) before the pug appears; it charges at
		-- 6.2, blows at 6.6, the cloud lets go at 9.2 and everything eases back from 12
		-- (Hold - 3). It shows its own Toxic radiation alert (ctx.ManualBanner).
		Hold = 15,
		FreezeLine = true,
		Clips = { { 0, "Idle", true }, { 6.2, "Radiation_Cloud" }, { 9.2, "Result_Success" } },
		Whispers = { { 0.3, "geiger counter: barking." }, { 9.4, "half-life: forever. good boy: also forever." } },
		Title = "NUCLEAR PUG",
		Color = Color3.fromRGB(150, 255, 60),
	},
	["404Dog"] = {
		Hold = 7,
		-- Depth_Error holds its last frame (the dog stays sunk) until Reassemble.
		Clips = { { 0, "Depth_Error" }, { 4, "Reassemble" } },
		Whispers = { { 0.5, "ERROR 404: DOG NOT FOUND" }, { 4.2, "dog found. it was behind you." } },
		Title = "404 DOG NOT FOUND",
		Color = Color3.fromRGB(80, 160, 255),
	},
	UnfinishedDog = {
		Hold = 6,
		Clips = { { 0, "Idle", true }, { 0.4, "Unfinished_Logic_Duplicate" }, { 5.6, "Idle", true } },
		Whispers = { { 0.3, "-- TODO: finish the dog" }, { 5.0, "it shipped anyway." } },
		Title = "THE UNFINISHED DOG",
		Color = Color3.fromRGB(255, 0, 255),
	},
	DivineDog = {
		-- Dogs/DivineDog: it lands at 9.8 (Blink), rolls at 10.4, its eyes close at 13.6
		-- (Blink); the light, the wheel and the seraph are gone by 16.4, after it sets off.
		-- The second whisper's typing times the ray that counts you: keep it at 10.0.
		Hold = 15,
		FreezeLine = true,
		Clips = { { 0, "Levitate_Walk", true }, { 9.8, "Blink" }, { 10.4, "Ability_MultiRoll" }, { 13.6, "Blink" } },
		Whispers = {
			{ 0.2, "BE NOT AFRAID." },
			{ 10.0, "it has counted every dog that ever lived. it counted you twice." },
		},
		Title = "BIBLICALLY ACCURATE DOG",
		Color = Color3.fromRGB(255, 236, 170),
		Banner = { At = 0.15, Style = "Divine", Kicker = "✦  A SECRET DOG DESCENDS  ✦", Text = "HEAVEN IS OPENING OVER THE ISLAND", Hold = 3.2 },
	},
	-- Never on the tongue: these arrive where they are obtained (SecretReveal).
	LongDog = {
		-- Its body runs a lap of the whole island (Dogs/LongDog): the head is back at the hole
		-- at 11, the tail pops out at 11.6 and the real dog appears at 13.6.
		Hold = 17.5,
		Clips = { { 0, "EXP_Confused", true }, { 13.6, "Happy" } },
		Whispers = {
			{ 0.5, "something is digging." },
			{ 4.2, "it is still coming out." },
			{ 8.4, "how long is a dog?" },
			{ 11.7, "oh. there's the tail." },
			{ 14.8, "perfectly normal dog." },
		},
		Title = "LONG DOG",
		Color = Color3.fromRGB(240, 196, 120),
	},
	Aurion = {
		Hold = 6.5,
		Clips = { { 0, "Sniff" }, { 2.3, "PrismEcho" }, { 4.4, "Happy" } },
		Whispers = {
			{ 0.3, "the light split into nine colours. one of them barked." },
			{ 3.0, "every tenth dig, it echoes." },
		},
		Title = "AURION",
		Color = Color3.fromRGB(150, 220, 255),
	},
	TheDog = {
		-- Dogs/TheDog, the eclipse: it waits underground until the ground opens (11.4), has
		-- risen by 14.2, the dawn comes at 18.6 and it walks at Hold.
		Hold = 24,
		SpeedScale = 0.5,
		FreezeLine = true,
		Clips = { { 0, "Stand_Idle", true }, { 11.4, "Ground_Opens" }, { 14.0, "Pet_Reaction" }, { 16.8, "Stand_Idle", true } },
		-- On the act's beats (the stare 4.9, the eye 6-9.4, the cutaway 10.6, the bow 15.4);
		-- each is typed (~0.06 s a character) before the next. The last line stays,
		-- breathing, while it walks.
		Whispers = {
			{ 0.5, "the tongue has gone quiet." },
			{ 4.95, "every dog on this island just turned around." },
			{ 7.7, "do not look away." },
			{ 10.4, "they know its name." },
			{ 16.0, "it was never a pet. you were." },
			{ 21.5, "good boy." },
		},
		-- The first of its two banners (THE DOG crosses every screen again at 14.2); the
		-- module adds the odds to the kicker (ctx.ManualBanner).
		Banner = { At = 0.4, Style = "Void", Title = "TOTAL ECLIPSE", Text = "do not look at the sun.", Hold = 3.4 },
		Title = "THE DOG",
		Color = Color3.fromRGB(255, 255, 255),
		-- Every dog on the map stares at THE DOG while it is around, for this long at most.
		StareSeconds = 120,
	},
}
return C
