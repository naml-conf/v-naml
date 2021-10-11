import os 

fn main() {

	mut token_list := []Token{}

	lines := os.read_lines('./test.naml') or {
		panic('error reading file test.naml')
		return
	}

	for line in lines {

		//TODO make it find the correct type
		token_list << TokenString{Tokens.text, line}
	}

	for token in token_list {
		println(token.value)
	}
}

enum Tokens {
    text		// ""
	block_open	// {
	block_close	// }
	integer		// i32
	double		// f64
	bool_true	// y
	bool_false	// n
	key			// name of a value
	equals		// an equals sign
}

interface Token {
	token_type	Tokens
	value		any
}

struct TokenString {
	token_type	Tokens
	value 		string
}

struct TokenDouble {
	token_type	Tokens
	value 		f64
}

struct TokenInt {
	token_type	Tokens
	value 		int
}

struct TokenBool {
	token_type	Tokens
	value 		bool
}

struct TokenBlock {
	token_type	Tokens
	value		[]Token
}