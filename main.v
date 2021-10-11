import os 

fn main() {

	mut token_list := []Token{}

	lines := os.read_lines('./test.naml') or {
		panic('error reading file test.naml')
		return
	}

	for line in lines {

		//TODO make it find the correct type
		token_list << Token{Tokens.key, line}
	}

	for token in token_list {
		println(token.value)
	}
}

enum Tokens {
    text
	block_open
	block_close
	integer
	double
	bool_true
	bool_false
	key
	equals
}

struct Token {
	token_type Tokens
	value string
}