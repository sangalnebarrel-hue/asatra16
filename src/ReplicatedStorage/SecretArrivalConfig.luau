-- Secret dogs arriving on the tongue. Read by DogLineSpawner (server) and by the
-- SecretArrivals cinematic (every client).
--   Hold        seconds the dog waits on its stage (unbuyable) while its arrival plays;
--               the next spawn waits too.
--   Clips       authored DogAnimationClips played during the hold: {seconds, clip, looped}.
--               The dog switches to Walk when the hold ends.
--   SpeedScale  while this dog is on the tongue the whole tongue moves at this speed.
--   FreezeLine  the whole tongue stops (every dog on it idles) during the hold.
--   Whispers    the mysterious lines typed at the top of every screen, {seconds, text}.
--   Title       the reveal card once the arrival lands.
--   Color       the dog's signature colour for UI and FX.
--   MegaSeconds how long its island-wide layer (SecretArrivals/Mega/<DogId>) lasts from the
--               arrival: the sky, the colossal set piece, the shockwave every player feels.
local C = {}
C.Version = 1
-- Secrets arrive this many studs down the tongue from DogSpawn: right in the giant
-- head's mouth opening, where the yards can see them (DogSpawn is deep in the throat).
C.Stage = 18
-- Optional uploaded sound assets. 0 keeps the built-in synthesized cue.
C.Sounds = { Drone = 0, Heartbeat = 0, Impact = 0, Glitch = 0, Choir = 0, Chime = 0, Whoosh = 0, Sting = 0 }
-- A client that sees an arrival later than this (joined late, streamed in) skips it.
C.LateGrace = 3

C.Dogs = {
	Cubedog = {
		Hold = 5.5,
		Clips = { { 0, "Idle", true }, { 2.3, "Impact" }, { 3.2, "Flip" }, { 4.2, "Happy" } },
		Whispers = { { 0.3, "something with six flat sides is coming." }, { 2.4, "every side of it is the front." } },
		Title = "CUBEDOG",
		MegaSeconds = 24,
		Color = Color3.fromRGB(86, 214, 255),
	},
	Dogdogdogdog = {
		Hold = 6.6,
		Clips = { { 0, "Split" }, { 3.5, "Reassemble" }, { 5.6, "Happy", true } },
		Whispers = {
			{ 1.6, "dog dog dog dog dog dog dog dog" },
			{ 4.6, "there were eight. now there is one. now there are eight." },
		},
		Title = "DOGDOGDOGDOG",
		MegaSeconds = 26,
		Color = Color3.fromRGB(255, 196, 64),
	},
	Spiderdog = {
		Hold = 6.2,
		Clips = { { 0, "Run", true }, { 2.9, "Ability_MultiDig" } },
		Whispers = {
			{ 0.3, "you checked under the bed. you never checked the ceiling." },
			{ 3.0, "eight legs. zero questions." },
		},
		Title = "SPIDERDOG",
		MegaSeconds = 26,
		Color = Color3.fromRGB(255, 120, 40),
	},
	WrongDog = {
		Hold = 6.4,
		Clips = { { 0, "EXP_Stare", true }, { 2.4, "UnstableEvent" }, { 5.6, "EXP_Unsettling", true } },
		Whispers = { { 0.4, "that is not how a dog is supposed to stand." }, { 2.6, "it is looking at you. only you." } },
		Title = "THE WRONG DOG",
		MegaSeconds = 26,
		Color = Color3.fromRGB(255, 40, 40),
	},
	NuclearPug = {
		Hold = 6.6,
		Clips = { { 0, "Idle", true }, { 1.2, "Radiation_Cloud" }, { 4.2, "Result_Success" } },
		Whispers = { { 0.3, "geiger counter: barking." }, { 4.4, "half-life: forever. good boy: also forever." } },
		Title = "NUCLEAR PUG",
		MegaSeconds = 28,
		Color = Color3.fromRGB(150, 255, 60),
	},
	["404Dog"] = {
		Hold = 7,
		-- Depth_Error holds its last frame (the dog stays sunk) until Reassemble.
		Clips = { { 0, "Depth_Error" }, { 4, "Reassemble" } },
		Whispers = { { 0.5, "ERROR 404: DOG NOT FOUND" }, { 4.2, "dog found. it was behind you." } },
		Title = "404 DOG NOT FOUND",
		MegaSeconds = 26,
		Color = Color3.fromRGB(80, 160, 255),
	},
	UnfinishedDog = {
		Hold = 6,
		Clips = { { 0, "Idle", true }, { 0.4, "Unfinished_Logic_Duplicate" }, { 5.6, "Idle", true } },
		Whispers = { { 0.3, "-- TODO: finish the dog" }, { 5.0, "it shipped anyway." } },
		Title = "THE UNFINISHED DOG",
		MegaSeconds = 26,
		Color = Color3.fromRGB(255, 0, 255),
	},
	DivineDog = {
		Hold = 7,
		Clips = { { 0, "Levitate_Walk", true }, { 2.8, "Blink" }, { 3.4, "Ability_MultiRoll" }, { 6.6, "Blink" } },
		Whispers = {
			{ 0.2, "BE NOT AFRAID." },
			{ 3.0, "it has counted every dog that ever lived. it counted you twice." },
		},
		Title = "BIBLICALLY ACCURATE DOG",
		MegaSeconds = 28,
		Color = Color3.fromRGB(255, 236, 170),
	},
	LongDog = {
		Hold = 7,
		Clips = { { 0, "EXP_Confused", true }, { 1.4, "Stretch" }, { 3.4, "DepthCharge" }, { 4.6, "Happy" } },
		Whispers = { { 0.3, "the hole kept going." }, { 3.6, "it is still coming out." } },
		Title = "LONG DOG",
		MegaSeconds = 26,
		Color = Color3.fromRGB(240, 196, 120),
	},
	-- Never on the tongue: arrives where it is won (SecretReveal).
	Aurion = {
		Hold = 6.5,
		Clips = { { 0, "Sniff" }, { 2.3, "PrismEcho" }, { 4.4, "Happy" } },
		Whispers = {
			{ 0.3, "the light split into nine colours. one of them barked." },
			{ 3.0, "every tenth dig, it echoes." },
		},
		Title = "AURION",
		MegaSeconds = 28,
		Color = Color3.fromRGB(150, 220, 255),
	},
	TheDog = {
		Hold = 14,
		SpeedScale = 0.5,
		FreezeLine = true,
		Clips = { { 0, "Stand_Idle", true }, { 6.4, "Ground_Opens" }, { 9.0, "Pet_Reaction" }, { 11.8, "Stand_Idle", true } },
		-- The last line stays (breathing) while it walks.
		Whispers = {
			{ 0.5, "the tongue has gone quiet." },
			{ 2.6, "every dog on this island just turned around." },
			{ 6.0, "they know its name." },
			{ 8.2, "do not look away." },
			{ 11.0, "it was never a pet. you were." },
			{ 13.0, "good boy." },
		},
		Title = "THE DOG",
		MegaSeconds = 44,
		Color = Color3.fromRGB(255, 255, 255),
		-- Every dog on the map stares at THE DOG while it is around, for this long at most.
		StareSeconds = 120,
	},
}
return C
