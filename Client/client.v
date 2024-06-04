import gg
import gx
import net.http { get }

const tiles_size = 64
const visu = 5
const win_width = tiles_size * (visu * 2 - 1)
const win_height = tiles_size * (visu * 2 - 1)

const bg_color = gg.Color{0, 0, 100, 255}

const serv_url = 'http://93.23.133.25:8100/'

struct App {
mut:
	ctx &gg.Context = unsafe { nil }

	player_name string  = "Moi"
	player_key  string

	host bool
	game bool

	world_map       []string
	player_pos_x    int
	player_pos_y    int
	player_gun      [][]int
	player_is_alive bool
	player_bigouden int

	ennemies        []string

	i int
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
		frame_fn: on_frame
		event_fn: on_event
		sample_count: 2
	)

	// lancement du programme/de la fenêtre
	app.ctx.run()
}

fn on_frame(mut app App) {
	//
	if app.game {
		if app.player_is_alive {
			// Ennemies 
			res := get(serv_url + 'phareouest/around_players/' + app.player_key) or { panic(err) }
			app.ennemies = res.body.split('/')
            
			app.ctx.begin()
			app.map_render(255)
			app.gun_render(150)
            app.ennemies_render(255)
			app.ctx.draw_circle_filled(win_width / 2, win_height / 2, (tiles_size / 2) - 10, gx.red)
            app.ctx.draw_text(win_width / 2, win_height / 2 - tiles_size / 2, '${app.player_name}', gx.TextCfg{ color: gx.black, size: 16, align: .center, vertical_align: .middle })
			
			app.ctx.show_fps()
			app.ctx.end()

			// Check if alive
            app.i += 1
			if app.i % 10 == 0 {
			    app.is_alive()
                
            }
		} else {
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
            app.i = 0

			app.ctx.begin()
			app.map_render(150)
			app.ctx.show_fps()
			app.ctx.end()
		}
	} else if app.player_key == '' {
		res := get(serv_url + 'phareouest/po') or { panic(err) }
		res_body := res.body.split('/')
		app.player_key = res_body[0]
		if res_body[1] == 'host' {
			app.host = true
		}
	} else {
		res := get(serv_url + 'phareouest/wait_start') or { panic(err) }
		res_body := res.body.split('/')
		nb_player := res_body[0]
		app.ctx.begin()
		app.ctx.show_fps()
		app.ctx.draw_text(win_width / 2, win_height / 2, 'Nb players : ${nb_player}', gx.TextCfg{ color: gx.black, size: 16, align: .center, vertical_align: .middle })
		app.ctx.end()
		if res_body[1] == 'true' {
			app.game = true
			res_map := get(serv_url + 'phareouest/map') or { panic(err) }
			mut map_tempo := res_map.body.split("', '")
			map_tempo[0] = map_tempo[0][2..]
			map_tempo[map_tempo.len - 1] = map_tempo[map_tempo.len - 1][..map_tempo[map_tempo.len - 1].len - 2]
			app.world_map = map_tempo
		}
	}
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
            app.ctx.draw_text(x_pos, y_pos  - tiles_size / 2, enn[2], gx.TextCfg{ color: gx.black, size: 16, align: .center, vertical_align: .middle })
        }
    }
}

fn on_event(e &gg.Event, mut app App) {
	coo_player_relative := [(e.mouse_x - e.window_width / 2), (e.mouse_y - e.window_height / 2)]
	match e.typ {
		.key_down {
			match e.key_code {
				.escape {
					app.ctx.quit()
				}
				.enter {
					if app.host && !app.game {
						get(serv_url + 'phareouest/start/' + app.player_key) or { panic(err) }
					}
				}
				.right {
					if app.game && app.player_is_alive {
						app.player_pos_x += 1
						if app.ennemies[0] != "none"{
							for mut enn_pos in app.ennemies{
								enn := enn_pos.split(", ")
								enn_pos = "${enn[0].int() + 1}, "+ enn[1] +", "+ enn[2]
							}
							spawn get(serv_url + 'phareouest/action/' + app.player_key + '/move/right')
						}
					}
				}
				.left {
					if app.game && app.player_is_alive {
						app.player_pos_x -= 1
						if app.ennemies[0] != "none"{
							for mut enn_pos in app.ennemies{
								enn := enn_pos.split(", ")
								enn_pos = "${enn[0].int() - 1}, "+ enn[1] +", "+ enn[2]
							}
							spawn get(serv_url + 'phareouest/action/' + app.player_key + '/move/left')
						}
					}
				}
				.down {
					if app.game && app.player_is_alive {
						app.player_pos_y += 1
						if app.ennemies[0] != "none"{
							for mut enn_pos in app.ennemies{
								enn := enn_pos.split(", ")
								enn_pos = enn[0] +", ${enn[1].int() + 1}, "+ enn[2]
							}
							spawn get(serv_url + 'phareouest/action/' + app.player_key + '/move/down')
						}
					}
				}
				.up {
					if app.game && app.player_is_alive {
						app.player_pos_y -= 1
						if app.ennemies[0] != "none"{
							for mut enn_pos in app.ennemies{
								enn := enn_pos.split(", ")
								enn_pos = enn[0] +", ${enn[1].int() - 1}, "+ enn[2]
							}
							spawn get(serv_url + 'phareouest/action/' + app.player_key + '/move/up')
						}
					}
				}
				else {}
			}
		}
		.mouse_down {
			match e.mouse_button {
				.left {
					for index, pos_tir in app.player_gun {
						x := coo_player_relative[0] - pos_tir[0] * tiles_size
						y := coo_player_relative[1] - pos_tir[1] * tiles_size
						if click_is_in_cube_center(x, y, tiles_size) {
							get(serv_url + 'phareouest/action/shoot/' + app.player_key + '/${index}') or { panic(err) }
						}
					}
				}
				else {}
			}
		}
		else {}
	}
}

fn click_is_in_cube_center(x f32, y f32, arrete f64) bool {
	if x <= arrete/2 && x >= -arrete/2 {
		if y <= arrete/2 && y >= -arrete/2 {
			return true
		}
	} else {
		return false
	}
	return false
}
