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
		players				map[string]int
		players_in_game_key	[]string
		players_in_game		[]Player
		
		// Map
		world_map	[]string
		visu		int = 5
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
				'po'{
					mut player_key := rand.string_from_set('azertyuiopqsdfghjklmwxcvbn', 8)
					for h.players_po_key.any(it == player_key){
						player_key = rand.string_from_set('azertyuiopqsdfghjklmwxcvbn', 8)
					}
					h.players_po_key << player_key
					res.body = player_key
					if h.players_po_key.len == 1{
						res.body += '/host'
					}
					else{
						res.body += '/not_host'
					}
				}
				'start'{
					eprintln('Start?')
					if actions[3] == h.players_po_key[0]{
						h.game_start()
					}
				}
				'wait_start'{
					res.body = '${h.players_po_key.len}/${h.game}'
				}
				'map'{
					res.body = '${h.world_map}'
				}
				'spawn'{
					if actions[3] in h.players_in_game_key{
						eprintln("Spawn ${actions[3]} as ${actions[4]}")
						player_cons_index := h.players[actions[3]]
						if !h.players_in_game[player_cons_index].alive{
								// Coor
								mut x := rand.int_in_range(0, 10) or {0}
								mut y := rand.int_in_range(0, 10) or {0}
								for !h.check_death(x, y){
									x = rand.int_in_range(0, 10) or {0}
									y = rand.int_in_range(0, 10) or {0}
								}

								gun := [[2, 0], [-2, 0], [0, 2], [0, -2]]

								h.players_in_game[player_cons_index] = Player{actions[4], true, x, y, Orientations.up, 1, gun}
								res.body = '${x}/${y}/${gun}'
								return res
						}
					}
				}
				'action'{
					if actions[3] in h.players_in_game_key{
						player_index := h.players[actions[3]]
						if h.players_in_game[h.players[actions[3]]].alive{
							match actions[4]{
								'move'{
									match actions[5]{
										'right'{
											h.players_in_game[player_index].x += 1
											h.players_in_game[player_index].orientation = Orientations.right
											x := h.players_in_game[player_index].x
											y := h.players_in_game[player_index].y
											h.players_in_game[player_index].alive = h.check_death(x, y)
										}
										'left'{
											h.players_in_game[player_index].x -= 1
											h.players_in_game[player_index].orientation = Orientations.left
											x := h.players_in_game[player_index].x
											y := h.players_in_game[player_index].y
											h.players_in_game[player_index].alive = h.check_death(x, y)
										}
										'down'{
											h.players_in_game[player_index].y += 1
											h.players_in_game[player_index].orientation = Orientations.down
											x := h.players_in_game[player_index].x
											y := h.players_in_game[player_index].y
											h.players_in_game[player_index].alive = h.check_death(x, y)
										}
										'up'{
											h.players_in_game[player_index].y -= 1
											h.players_in_game[player_index].orientation = Orientations.up
											x := h.players_in_game[player_index].x
											y := h.players_in_game[player_index].y
											h.players_in_game[player_index].alive = h.check_death(x, y)
										}
										else{
											status_code = 404
											res.body = 'Not found'
											eprintln("Bad move ${actions[5]}")
										}
									}
								}
								'pick'{
									match actions[5]{
										'right'{
											
										}
										'left'{
											
										}
										'down'{
											
										}
										'up'{
											
										}
										else{
											status_code = 404
											res.body = 'Not found'
										}
									}
								}
								'shoot'{
									shoot_pos := h.players_in_game[player_index].gun[actions[5].int()]
									x := shoot_pos[0] + h.players_in_game[player_index].x
									y := shoot_pos[1] + h.players_in_game[player_index].y
									for mut player in h.players_in_game{
										if player.x == x && player.y == y{
											player.alive = false
										}
									}
								}
								else{
									status_code = 404
									res.body = 'Not found'
								}
							}
						}
					}
				}
				'alive'{
					if actions[3] in h.players_in_game_key{
						if h.players_in_game[h.players[actions[3]]].alive{
							res.body = 'true/${h.players_in_game[h.players[actions[3]]].bigouden}'
						}
						else{
							res.body = 'false/1'
						}
					}
				}
				'around_players'{
					if actions[3] in h.players_in_game_key{
						player_pos_x	:= h.players_in_game[h.players[actions[3]]].x
						player_pos_y	:= h.players_in_game[h.players[actions[3]]].y
						res.body = "none"
						for y_view in -h.visu..(h.visu + 1){
							y := y_view + player_pos_y

							for x_view in -h.visu..(h.visu + 1){
								x := x_view + player_pos_x

								for index, player in h.players_in_game{
									if index != h.players[actions[3]]{
										if player.x == x && player.y == y {

											if res.body == "none"{
												res.body = "${x_view}, ${y_view}, ${player.name}"
											}
											else{
												res.body += "/${x_view}, ${y_view}, ${player.name}"
											}
										}
									}
								}
							}
						}
					}						
				}
				'around_items'{
					//get les items dans le champ de vision
				}
				else{
					status_code = 404
					res.body = 'Not found'
					eprintln("Bad instruction: ${actions[2]}")
				}
			}
		}
		else{
			status_code = 404
			res.body = 'Not found'
			eprintln("Bad game instruction: ${actions[1]}")
		}
	}
	res.status_code = status_code
	return res
}

fn main() {
	eprintln('server started')
	mut server := Server{
		addr:':8100'
		handler:  Handler{}
	}
	server.listen_and_serve()
}

fn (h Handler) check_death(x int, y int) bool{
	if 0 <= x && 0 <= y{
		if y < h.world_map.len{
			if x < h.world_map[y].len{
				if h.world_map[y][x].ascii_str() == "e"{
					return false
				} 
				else if h.world_map[y][x].ascii_str() != "h"{
					eprintln(h.world_map[y][x].ascii_str())
				}
			}
		}
	}
	return true
}

struct Player {
	mut:
		name		string
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
	
	eprintln('Map created')
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
	eprintln('Game Started')
}

fn (mut h Handler) map_crea(){
	x_len := 20
	y_len := 10
	h.world_map = []string{len: y_len, cap: 10, init: map_init(index, y_len, x_len)}
}

fn map_init(index int, y_len int, x_len int) string{
	mut y_map := ""
	if index == 0 || index == y_len -1 {
		// Default
		y_map = 'eeeeeeeeee' + 'eeeeeeeeee'
	}else if index%4 == 0{
		y_map = 'eehhhhhhhh' + 'eehhhhhhee'
	}else if index%3 == 0{
		y_map = 'eeehhhhhhe' + 'ehhhhhhhee'
	}else if index%2 == 0{
		y_map = 'eehhhhhhhe' + 'hhhhhhhhee'
	}else{
		// Default
		y_map = 'ehhhhhhhhh' + 'hhhhhhhhhe'
	}

	for y_map.len < x_len{
		y_map += "e"
	}
	return y_map
}

fn (mut h Handler) game_end(){
	h.game = false
	
	// Map
	h.world_map.clear()

	// players

	h.players_in_game_key.clear()

	h.players_in_game.clear()

	h.players.clear()
}

