
#define QUIZ_DIFFICULTY_TRIVIAL 0
#define QUIZ_DIFFICULTY_EASY 1
#define QUIZ_DIFFICULTY_NORMAL 2
#define QUIZ_DIFFICULTY_HARD 3
#define QUIZ_DIFFICULTY_BULLSHIT 2

ABSTRACT_TYPE(/datum/quiz)
/datum/quiz
	var/text = "This question has no text, yet it should. Why is that? (Hint: You should not be seeing this)"
	var/list/answers = list("bug", "issue", "error")
	var/hint = null
	var/difficulty = QUIZ_DIFFICULTY_EASY

	/// Checks to see if the answer is in the sentence. "search_limit" is the number of words to check before giving up.
	proc/is_answer_sentence(var/sentence, var/search_limit = 7)
		if(!text)
			return
		var/list/words = splittext(text, " ")
		var/check_count = 0
		for(var/word in words)
			if(is_answer(word))
				return TRUE
			if(check_count >= search_limit)
				break
			check_count++
		return FALSE

	proc/is_answer(var/response)
		var/response_cleaned = ckey(response)
		for(var/answer in src.answers)
			if(startswith(answer, response_cleaned) && (length(answer) < length(response_cleaned) + 2)) // for plural words
				return TRUE
		return FALSE

// ============================================ Riddles ================================================

ABSTRACT_TYPE(/datum/quiz/riddle)
/datum/quiz/riddle

/datum/quiz/riddle/ice_freeze
	text = "What is made of water, yet cannot freeze?"
	answers = list("ice")
	hint = "There are three normal states of matter."
	difficulty = QUIZ_DIFFICULTY_TRIVIAL

// ============================================ Trivia ================================================

ABSTRACT_TYPE(/datum/quiz/trivia)
/datum/quiz/trivia

/datum/quiz/trivia/basketball
	text = "In what year was basketball officially declared as illegal?"
	answers = list("2041")
	hint = "It is the square root of the product of 26533 x 157."
	difficulty = QUIZ_DIFFICULTY_HARD

/datum/quiz/trivia/typhon
	text = "What is the name of the Frontier brown dwarf known for being the main source of plasma in the system?"
	answers = list("typhon")
	hint = "It is named after a giant serpent in Greek mythology that attempted to overthrow Zeus."
	difficulty = QUIZ_DIFFICULTY_HARD

/datum/quiz/trivia/teddybear
	text = "What is the name of the popular toy named after US president Theodore Roosevelt?"
	answers = list("teddy", "teddybear")
	hint = "It is in the shape of a bear."
	difficulty = QUIZ_DIFFICULTY_EASY

/datum/quiz/trivia/grifening
	text = "What is the name of the two-player collectable card game created in the year 2036 that gained immense popularity among space nerds?"
	answers = list("spacemen", "grifening", "stg")
	hint = "The cards can be found in the gaming vending machine."
	difficulty = QUIZ_DIFFICULTY_EASY

/datum/quiz/trivia/miraclium_melt
	text = "What is the melting point of miraclium (AKA miracle matter)?"
	hint = "Can be found using the material analyser."
	difficulty = QUIZ_DIFFICULTY_NORMAL

	New()
		. = ..()
		var/datum/material/miraclium = getMaterial("miracle")
		var/melting_point = miraclium.getProperty("melting_point")
		answers = list("[melting_point]", "[TO_CELSIUS(melting_point)]", "[TO_FAHRENHEIT(melting_point)]")


