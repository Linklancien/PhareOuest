module main

import net.http { CommonHeader, Request, Response, Server }
import rand

struct  Handler {
	mut:
		// Lobby
		players_po_key	[]string

		// Game
		// Map player_key -> player_index for players_in_game
		game				bool
		players				map
		players_in_game_key	[]string
		players_in_game		[]Player
		
		// Map
		world_map	[][]string
}

fn (mut h Handler) handle(req Request) Response {
	mut res := Response{
		header: http.new_header_from_map({
			CommonHeader.content_type: 'text/plain'
		})
	}

	mut status_code := 200
	actions := req.url.split('/')

	match actions[1]{
		'phareouest'{
			match actions[2]{
				"po"{
					mut player_key := rand.ascii(8)
					for h.players_po_key.any(it == player_key){
						player_key = rand.ascii(8)
					}
					h.players_po_key << player_key
					res.body = player_key
					if h.players_po_key.len == 1{
						res.body += "/host"
					}
				}
				"start"{
					if actions[3] == h.players_po_key[0]{
						h.game_start()
					}
				}
				"wait_start"{
					res.body = "${h.players_po_key.len}/${h.game}"
				}
				"map"{
					res.body = "${h.world_map}"
				}
				"spawn"{
					if actions[3] in h.players_in_game_key{
						player_cons_index := h.players[actions[3]]
						if !h.players_in_game[player_cons_index].alive{
								// Coor
								x := rand.int_in_range(0, 10) or {0}
								y := rand.int_in_range(0, 10) or {0}

								gun := [[2, 0], [-2, 0], [0, 2], [0, -2]]

								h.players_in_game[player_cons_index] = Player{true, x, y, Orientations.up, 1, gun}
								res.body = "${x}/${y}/${gun}"
								return res
						}
					}
				}
				"action"{
					if actions[3] in h.players_in_game_key{
						player_index := h.players[actions[3]]
						match actions[4]{
							"move"{
								match actions[5]{
									"right"{
										h.players_in_game[player_index].x += 1
										h.players_in_game[player_index].orientation = Orientations.right
									}
									"left"{
										h.players_in_game[player_index].x -= 1
										h.players_in_game[player_index].orientation = Orientations.left
									}
									"down"{
										h.players_in_game[player_index].y += 1
										h.players_in_game[player_index].orientation = Orientations.down
									}
									"up"{
										h.players_in_game[player_index].y -= 1
										h.players_in_game[player_index].orientation = Orientations.up
									}
									else{
										status_code = 404
										res.body = "Not found"
									}
								}
							}
							"pick"{
								match actions[5]{
									"right"{
										
									}
									"left"{
										
									}
									"down"{
										
									}
									"up"{
										
									}
									else{
										status_code = 404
										res.body = "Not found"
									}
								}
							}
							"shoot"{
								shoot_pos := h.players_in_game[player_index].gun[actions[5]]
							}
							else{
								status_code = 404
								res.body = "Not found"
							}
						}
					}
				}
				"alive"{
					if actions[3] in h.players_in_game_key{
						if h.players[actions[3]].alive{
							res.body = "true/${h.players[actions[3]].bigouden}"
						}
						else{
							res.body = "false"
						}
					}
				}
				"around_players"{
					// get les players dans ton champ de vision (plus petit quand y a la pluie)
				}
				"around_items"{
					//get les items dans le champ de vision
				}
				else{
					status_code = 404
					res.body = "Not found"
				}
			}
		}
		else{
			status_code = 404
			res.body = "Not found"
		}
	}
	res.status_code = status_code
	return res
}

fn main() {
	eprintln("server started")
	mut server := Server{
		addr:":8100"
		handler:  Handler{}
	}
	server.listen_and_serve()
}

struct Player {
	mut:
		alive		bool
		x			int
		y			int
		orientation	Orientations
		bigouden	int
		gun			[][]int
}

enum Orientations {
	right
	left
	down
	up
}

fn (mut h  Handler) game_start(){
	// Map
	h.map_crea()
	
	// players
	h.players_in_game_key = h.players_po_key
	h.players_po_key	= []

	for _ in 0..h.players_in_game_key.len{
		h.players_in_game << Player{}
	}

	mut player_nb := 0
	for key in h.players_in_game_key{
		h.players[key] = player_nb
		player_nb += 1
	}
		
	h.game = true
}

fn (mut h Handler) map_crea(){

}

// fn (mut h Handler) game_end(){
// 	h.game = false
	
// 	// Map
// 	h.world_map = [][]

// 	// players

// 	h.players_in_game_key = []

// 	h.players_in_game = []

// 	h.players.clear()
// }

