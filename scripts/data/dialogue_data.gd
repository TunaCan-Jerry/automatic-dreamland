class_name DialogueData
extends RefCounted


static func claira_first_meeting() -> Array:
	return [
		{speaker = "Claira", text = "There you are. I was starting to think you'd sleep through the whole morning.", mode = "normal"},
		{speaker = "Claira", text = "Grandma wanted to see you, by the way. Something about an errand.", mode = "normal"},
		{speaker = "Claira", text = "Come on, I'll walk with you.", mode = "normal"},
	]


static func tree_kiss() -> Array:
	return [
		{speaker = "", text = "Claira pulls you behind the old tree.", mode = "cinematic"},
		{speaker = "", text = "A stolen moment. The village sounds feel far away.", mode = "cinematic"},
		{speaker = "Claira", text = "...okay. Grandma's waiting. Try to look normal.", mode = "normal"},
	]


static func elder_conversation() -> Array:
	return [
		{speaker = "Elder", text = "Come in, come in. I just put the kettle on.", mode = "normal"},
		{speaker = "Elder", text = "Sit down. How are you? How's your father's back?", mode = "normal"},
		{speaker = "You", text = "He says it's fine. It's not fine.", mode = "normal"},
		{speaker = "Elder", text = "Ha. That sounds like him.", mode = "normal"},
		{speaker = "Elder", text = "Listen, I need a favor. Could you run a package to the Millers' homestead?", mode = "normal"},
		{speaker = "Elder", text = "And while you're there — ask them for a small box I left last visit. They'll know the one.", mode = "normal"},
		{speaker = "You", text = "Sure. I'll head out now.", mode = "normal"},
		{speaker = "Elder", text = "No rush. Well — before dark, maybe. Be careful on the road.", mode = "normal"},
		{speaker = "Claira", text = "I'll stay and help grandma with the garden. Don't take forever.", mode = "normal"},
	]


static func tavern_keeper() -> Array:
	return [
		{speaker = "Tavern Keeper", text = "Morning! You look just like your mother at that age, you know that?", mode = "normal"},
		{speaker = "Tavern Keeper", text = "Your dad was in here last night. Said the south field's coming in nicely this year.", mode = "normal"},
		{speaker = "Tavern Keeper", text = "Tell your folks I said hello!", mode = "normal"},
	]


static func tavern_keeper_after_quest() -> Array:
	return [
		{speaker = "Tavern Keeper", text = "Off on an errand? Don't let the road critters give you trouble!", mode = "normal"},
	]


static func old_couple() -> Array:
	return [
		{speaker = "Old Man", text = "Good morning, dear. Beautiful day, isn't it?", mode = "normal"},
		{speaker = "Old Woman", text = "You remind me of your father when he was young. Same walk.", mode = "normal"},
		{speaker = "Old Man", text = "The birds have been flying east for days now. All of them. Odd, that.", mode = "normal"},
		{speaker = "Old Woman", text = "Oh, don't worry the child with your bird nonsense.", mode = "normal"},
	]


static func dad_greeting() -> Array:
	return [
		{speaker = "Dad", text = "Hey, kiddo. Have a good day out there.", mode = "normal"},
	]


static func dad_after_quest() -> Array:
	return [
		{speaker = "Dad", text = "Be safe out there. And don't dawdle — your mother worries.", mode = "normal"},
	]


static func house_photo() -> Array:
	return [
		{speaker = "", text = "A family photo on the shelf. Mom, Dad, you. A normal morning.", mode = "normal"},
	]


static func flavor_kid() -> Array:
	return [
		{speaker = "Kid", text = "Tag! You're it! ...oh wait, you're a grown-up. Never mind.", mode = "normal"},
	]


static func flavor_farmer() -> Array:
	return [
		{speaker = "Farmer", text = "Morning! Crops are looking good this season.", mode = "normal"},
	]


static func flavor_patron() -> Array:
	return [
		{speaker = "Patron", text = "Little early for the tavern, isn't it? ...don't judge me.", mode = "normal"},
	]


static func homestead_npc() -> Array:
	return [
		{speaker = "Miller", text = "Oh, from the elder? Thank you kindly.", mode = "normal"},
		{speaker = "Miller", text = "And here's that box she left. Told her I'd keep it safe.", mode = "normal"},
		{speaker = "", text = "You received the elder's trinket.", mode = "normal"},
		{speaker = "Miller", text = "Safe travels back now.", mode = "normal"},
	]


static func smoke_on_horizon() -> Array:
	return [
		{speaker = "", text = "As you crest the hill, you see smoke rising from the direction of the village.", mode = "cinematic"},
		{speaker = "", text = "Too much smoke.", mode = "cinematic"},
	]


static func finding_claira() -> Array:
	return [
		{speaker = "", text = "The village is gone.", mode = "cinematic"},
		{speaker = "", text = "Everything is ash and ember. The fountain is shattered. The tavern is a skeleton.", mode = "cinematic"},
		{speaker = "", text = "Near the elder's house, a faint shimmer in the air. A barrier of light, cracking, fading.", mode = "cinematic"},
		{speaker = "", text = "Behind it — Claira. Alive. Barely.", mode = "cinematic"},
		{speaker = "", text = "The barrier shatters as you reach her. The elder's last magic, spent.", mode = "cinematic"},
		{speaker = "Claira", text = "She... grandma, she...", mode = "normal"},
		{speaker = "Claira", text = "...she told me to stay inside the light. No matter what.", mode = "normal"},
		{speaker = "Claira", text = "...I could hear everything.", mode = "normal"},
	]


static func leaving_village() -> Array:
	return [
		{speaker = "", text = "The trinket. Claira. And the road ahead.", mode = "cinematic"},
		{speaker = "", text = "There's nothing left here.", mode = "cinematic"},
	]
