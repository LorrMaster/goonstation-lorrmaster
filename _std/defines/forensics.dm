
#define FORENSIC_CATEGORY_NOTE 1
#define FORENSIC_CATEGORY_FINGERPRINT 2
#define FORENSIC_CATEGORY_DNA 3
#define FORENSIC_CATEGORY_SCAN 4
#define FORENSIC_CATEGORY_COMPUTER_LOG 5

#define FORENSIC_REMOVABLE (1 << 1)
#define FORENSIC_IS_JUNK (1 << 2)
#define FORENSIC_ADMIN_ONLY (1 << 3)

#define FORENSIC_CHARS_UP "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define FORENSIC_CHARS_LOW "abcdefghijklmnopqrstuvwxyz"
#define FORENSIC_CHARS_NUM "1234567890"
#define FORENSIC_CHARS_FP "abcdegnopqrsuvxy"

#define FORENSIC_CHARS_DNA "CGAT"
#define FORENSIC_CHARS_ALL (FORENSIC_CHARS_UP + FORENSIC_CHARS_LOW + FORENSIC_CHARS_NUM)

var/static/list/chars_upper = list("A","B","C","D","E","F","G","H","I","J","K","L","M",
								   "N","O","P","Q","R","S","T","U","V","W","X","Y","Z")
var/static/list/chars_lower = list("a","b","c","d","e","f","g","h","i","j","k","l","m",
								   "n","o","p","q","r","s","t","u","v","w","x","y","z")
var/static/list/chars_num = list("0","1","2","3","4","5","6","7","8","9")
var/static/list/chars_symbols = list("!","#","_","%","&","+","=","?")
var/static/list/chars_hex = chars_num + list("A","B","C","D","E","F")

// Remove letters that can be confused with numbers at a glance
var/static/list/chars_upper_limit = chars_upper - list("D","I","O","Q")
var/static/list/chars_lower_limit = chars_lower - list("i","j","l","o")

// chars_fingerprint is limited to 'round-ish' letters (with a few exceptions)
var/static/list/chars_fingerprint = list("a","b","c","d","e","g","n","o","p","r","s","u","v","x","y")
//
