import gg
import gx
import net.http { get }
import os

const tiles_size = 64
const espacement = 64
const visu = 5
const win_width = tiles_size * (visu * 2 - 1)
const win_height = tiles_size * (visu * 2 - 1)

const bg_color = gg.Color{0, 0, 100, 255}

const serv_url = 'http://93.23.133.25:8100/'
const font_path = os.resource_abs_path('0xProtoNerdFontMono-Regular.ttf')

enum Game_mode {
	lobby
	game
	spectator
}

struct App {
mut:
	ctx &gg.Context = unsafe { nil }

	player_name string  = "Moi"
	player_key  string

	host bool
	game Game_mode
	
	// Pause
	pause			bool
	pause_scroll	int
	text_cfg		gx.TextCfg
	
	// imput_action
	list_imput_action		[]Actions
	list_action_key_code	[]int
	imput_action_change		Actions

	world_map       []string
	player_pos_x    int
	player_pos_y    int
	player_gun      [][]int
	player_is_alive bool
	player_bigouden int

	ennemies        []string
}

fn main() {
	mut app := &App{}
	app.ctx = gg.new_context(
		width: win_width
		height: win_height
		create_window: true
		window_title: '- Phare Ouest -'
		user_data: app
		bg_color: bg_color
		init_fn:	on_init
		frame_fn: on_frame
		event_fn: on_event
		sample_count: 2
		font_path: font_path
	)

	// lancement du programme/de la fenêtre
	app.ctx.run()
}

fn on_init(mut app App) {
	app.list_imput_action_key_code_init()
	player_infos := os.read_file(os.abs_path("player_infos")) or{"Moi/"}.split('/')  // player_name / player_key
	app.player_name = player_infos[0]
	app.player_key = player_infos[1]
	if player_infos.len == 3{
		if player_infos[2] == "host"{
			app.host = true
		}
	}
	dump(player_infos)
	test := get(serv_url + 'phareouest/verif/' + app.player_key) or { panic(err) }
	if test.body == 'false' {
		// Ask for a key & being place in the queue
		res := get(serv_url + 'phareouest/po') or { panic(err) }
		res_body := res.body.split('/')
		app.player_key = res_body[0]
		if res_body[1] == 'host' {
			app.host = true
		}
		infos := app.player_name +"/"+ app.player_key
		os.write_file(os.abs_path("player_infos"), if app.host{infos +"/host"} else {infos}) or{}
		app.game = Game_mode.lobby
	}
	dump(app.player_key)
}

fn on_frame(mut app App) {
	mut transparence := u8(255)
	app.ctx.begin()
	if app.pause{
		transparence = 150
	}

	if app.game == Game_mode.game{
		if app.player_is_alive {
			// Ennemies 
			res := get(serv_url + 'phareouest/around_players/' + app.player_key) or { panic(err) }
			app.ennemies = res.body.split('/')
            
			app.map_render(transparence)
			app.gun_render(transparence - 100)
            app.ennemies_render(transparence)
			app.ctx.draw_circle_filled(win_width / 2, win_height / 2, (tiles_size / 2) - 10, attenuation(gx.red, transparence))
			app.text_rect_render(win_width / 2, (win_height- tiles_size)/ 2, '${app.player_name} B:${app.player_bigouden}', transparence - 100)
			
			app.ctx.show_fps()

			// Check if alive
			spawn app.is_alive()
		}
		else {
            res := get(serv_url + 'phareouest/spawn/' + app.player_key +"/"+ app.player_name) or { panic(err) }
            res_body := res.body.split('/')
            app.player_pos_x = res_body[0].int()
            app.player_pos_y = res_body[1].int()

            app.player_gun = []

            // res_body[2] -> player gun
            // ex res_body[2] ->  "[[2, 0], [-2, 0], [0, 2], [0, -2]]"
            mut gun_tempo := res_body[2].split('], [')

            // ex gun_tempo ->  ["[[2, 0", "-2, 0", "0, 2", "0, -2]]"]
            gun_tempo[0] = gun_tempo[0][2..]
            gun_tempo[gun_tempo.len - 1] = gun_tempo[gun_tempo.len - 1][..gun_tempo[gun_tempo.len - 1].len - 2]

            // ex gun_tempo ->  ["2, 0", "-2, 0", "0, 2", "0, -2"]
            for att in gun_tempo {
                att_split := att.split(', ')
                app.player_gun << [att_split[0].int(), att_split[1].int()]
            }
            app.player_is_alive = true

			app.map_render(transparence - 100)
			app.ctx.show_fps()
		}
	}
	else if app.game == Game_mode.spectator {
		app.text_rect_render(win_width / 2, win_height/ 2, 'Wait the End of the curent game please', transparence)
	}
	else if app.player_key == '' {
		// Ask for a key & being place in the queue
		res := get(serv_url + 'phareouest/po') or { panic(err) }
		res_body := res.body.split('/')
		app.player_key = res_body[0]
		if res_body[1] == 'host' {
			app.host = true
		}
		infos := app.player_name +"/"+ app.player_key
		os.write_file(os.abs_path("player_infos"), if app.host{infos +"/host"} else {infos}) or{}
		app.game = Game_mode.lobby
	}
	else if app.game == Game_mode.lobby{
		// Render the lobby
		res := get(serv_url + 'phareouest/wait_start/'+ app.player_key) or { panic(err) }
		res_body := res.body.split('/')
		nb_player := res_body[0]

		app.ctx.show_fps()
		
		if app.host{
			app.text_rect_render(win_width / 2, (win_height - espacement)/ 2, 'Nb players : ${nb_player}', transparence)
			app.text_rect_render(win_width / 2, win_height/ 2, 'You are the HOST', transparence)
			app.text_rect_render(win_width / 2, (win_height + espacement)/ 2, "Press " + key_code_name[app.list_action_key_code[Actions.start]], transparence)
		}
		else{
			app.text_rect_render(win_width / 2, win_height / 2, 'Nb players : ${nb_player}', transparence)
		}
		
		if res_body[1] == 'true' {
			app.game = Game_mode.game
			res_map := get(serv_url + 'phareouest/map') or { panic(err) }
			mut map_tempo := res_map.body.split("', '")
			map_tempo[0] = map_tempo[0][2..]
			map_tempo[map_tempo.len - 1] = map_tempo[map_tempo.len - 1][..map_tempo[map_tempo.len - 1].len - 2]
			app.world_map = map_tempo
		}
	}

	if app.pause{
		app.settings_render()
	}
	app.ctx.end()
}

fn (app App) map_render(transparence u8) {
	for y_view in -visu .. (visu + 1) {
		y := y_view + app.player_pos_y
		if y < app.world_map.len && y >= 0 {

			for x_view in -visu .. (visu + 1) {
				x := x_view + app.player_pos_x
				if x < app.world_map[y].len && x >= 0 {
					

					mut color := gx.Color{100, 0, 0, transparence}
					if app.world_map[y][x].ascii_str() == 'e' {
						color = gx.Color{0, 0, 100, transparence}
					} else if app.world_map[y][x].ascii_str() == 'h' {
						color = gx.Color{0, 100, 0, transparence}
					} else {
						println(app.world_map[y][x].ascii_str())
					}
					x_pos := x_view * tiles_size + win_width / 2 - tiles_size / 2
					y_pos := y_view * tiles_size + win_height / 2 - tiles_size / 2

					app.ctx.draw_square_filled(x_pos, y_pos, tiles_size, color)
					app.ctx.draw_square_empty(x_pos, y_pos, tiles_size, gx.black)
				}
			}
		}
	}
}

fn (mut app App) is_alive() {
	res := get(serv_url + 'phareouest/alive/' + app.player_key) or { panic(err) }
	res_body := res.body.split('/')
	if res_body[0] == 'true' {
		app.player_bigouden = res_body[1].int()
	} else {
		app.player_is_alive = false
	}
}

fn (app App) gun_render(transparence u8) {
	color := gx.Color{200, 0, 0, transparence}
	for coos in app.player_gun {
		x_pos := coos[0] * tiles_size + win_width / 2 - tiles_size / 2
		y_pos := coos[1] * tiles_size + win_height / 2 - tiles_size / 2

		app.ctx.draw_square_filled(x_pos, y_pos, tiles_size, color)
	}
}

fn (app App) ennemies_render(transparence u8) {
	color := gx.Color{238, 0, 238, transparence}
    if app.ennemies[0] != "none"{
        for enn_pos in app.ennemies {
            enn := enn_pos.split(", ")
            x_pos := enn[0].int() * tiles_size + win_width / 2
            y_pos := enn[1].int() * tiles_size + win_height / 2

            app.ctx.draw_circle_filled(x_pos, y_pos, (tiles_size / 2) - 10, color)
			app.text_rect_render(x_pos, y_pos  - tiles_size / 2, enn[2], transparence - 75)
        }
    }
}

fn on_event(e &gg.Event, mut app App) {
	coo_player_relative := [(e.mouse_x - e.window_width / 2), (e.mouse_y - e.window_height / 2)]
	match e.typ {
		.key_down {
			app.imput(int(e.key_code))
		}
		.mouse_down {
			match e.mouse_button {
				.left {
					if app.pause{
						app.pause_check_boutons(e.mouse_x, e.mouse_y)
					}
					else{
						for index, pos_tir in app.player_gun {
							x := coo_player_relative[0] - pos_tir[0] * tiles_size
							y := coo_player_relative[1] - pos_tir[1] * tiles_size
							if click_is_in_square_center(x, y, tiles_size) {
								spawn get(serv_url + "phareouest/action/"+ app.player_key + "/shoot/${index}")
								break
							}	
						}
					}
				}
				else {}
			}
		}
		else {}
	}
}

fn click_is_in_square_center(x f32, y f32, arrete f64) bool {
	if x <= arrete/2 && x >= -arrete/2 {
		if y <= arrete/2 && y >= -arrete/2 {
			return true
		}
	} else {
		return false
	}
	return false
}
