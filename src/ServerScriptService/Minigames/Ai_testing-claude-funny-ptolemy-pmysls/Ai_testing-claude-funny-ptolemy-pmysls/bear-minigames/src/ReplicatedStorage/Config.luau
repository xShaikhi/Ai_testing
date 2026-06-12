local Config = {}

Config.MinPlayers = 1

Config.Timing = {
	Intermission = 15,
	MapLoad = 3,
	RoundLength = 120,
	EndScreen = 8,
}

Config.Lobby = {
	Size = 120,
	SpawnHeight = 2,
}

Config.Map = {
	Size = 150,
	WallHeight = 30,
}

Config.Bear = {
	Height = 9,
	WalkSpeed = 10,
	ChaseSpeed = 20,
	DetectionRange = 70,
	AttackRange = 6,
	LoseTargetRange = 100,
	AttackCooldown = 2,
	StunDuration = 3,
	RoarBeforeChase = true,
}

Config.HoneyHunt = {
	JarsToWin = 8,
	JarsSpawned = 14,
	CoinsPerJar = 2,
}

Config.Rewards = {
	Survived = 20,
	WonObjective = 40,
	Participation = 12,
}

return Config
