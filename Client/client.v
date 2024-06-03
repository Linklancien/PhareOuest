import gg
import gx
import net.http {get}

const tiles_size    = 64
const visu          = 5
const win_width     = tiles_size*(visu*2 - 1)
const win_height    = tiles_size*(visu*2 - 1)



const bg_color     = gg.Color{}

const serv_url     = 'http://93.23.133.25:8100/'



struct App {
mut:
    ctx    &gg.Context = unsafe { nil }
    

    player_name     string
    player_key      string

    host            bool
    game			bool

    world_map       []string
    player_pos_x    int
    player_pos_y    int
    player_gun      [][]int
    player_is_alive bool
    player_bigouden int

    player_in_range [][]int
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

    //lancement du programme/de la fenêtre
    app.ctx.run()
}

fn on_frame(mut app App) {
    //
    if app.game{
        if app.player_is_alive{
            app.ctx.begin()
            app.map_render(255)
            app.gun_render(150)
            app.ctx.draw_circle_filled(win_width/2, win_height/2, (tiles_size/2) - 10, gx.red)
            app.ctx.end()

            // Check if alive
            res := http.get(serv_url + 'phareouest/alive/' + app.player_key) or {panic(err)}
            res_body := res.body.split('/')
            if res_body[0] == 'true'{
                app.player_bigouden = res_body[0].int()
            }
            else{
                app.player_is_alive = false
            }
        }
        else{
            res := http.get(serv_url + 'phareouest/spawn/' + app.player_key) or {panic(err)}
            res_body := res.body.split('/')
            app.player_pos_x = res_body[0].int()
            app.player_pos_y = res_body[1].int()
            // res_body[2] -> player gun
            app.player_gun = [[2, 0], [-2, 0], [0, 2], [0, -2]]
            app.player_is_alive = true

            app.ctx.begin()
            app.map_render(150)
            app.ctx.end()
        }
    }
    else if app.player_key == ''{
        res         := http.get(serv_url + 'phareouest/po') or {panic(err)}
        res_body    := res.body.split('/')
        app.player_key = res_body[0]
        if res_body[1] == 'host'{
            app.host = true
        }
    }
    else{
        res         := http.get(serv_url + 'phareouest/wait_start') or {panic(err)}
        res_body    := res.body.split('/')
        nb_player   := res_body[0]
        println(nb_player)
        println(app.host)
        if res_body[1] == 'true'{
            app.game = true
            res_map := http.get(serv_url + 'phareouest/map') or {panic(err)}
            mut map_tempo := res_map.body.split(", ")
            map_tempo[0] = map_tempo[0][1..]
            map_tempo[map_tempo.len - 1] = map_tempo[map_tempo.len - 1][..map_tempo[map_tempo.len - 1].len - 1]
            app.world_map = map_tempo
        }
    }
}

fn (app App) map_render(transparence u8){
    for y_view in -visu..(visu + 1){
        if y_view + app.player_pos_y < app.world_map.len && y_view + app.player_pos_y >= 0{
            y := y_view + app.player_pos_y

            for x_view in -visu..(visu + 1){
                if x_view + app.player_pos_x < app.world_map[y].len && x_view + app.player_pos_x >= 0{
                    x := x_view + app.player_pos_x

                    mut color := gx.Color{}
                    if app.world_map[y][x].ascii_str() == 'e'{
                        color = gx.Color{0, 0, 100, transparence}
                    }
                    else if app.world_map[y][x].ascii_str() == 'h'{
                        color = gx.Color{0, 100, 0, transparence}
                    }
                    x_pos := x_view*tiles_size + win_width/2    - 3*tiles_size/2
                    y_pos := y_view*tiles_size + win_height/2   - tiles_size/2
                    
                    app.ctx.draw_square_filled(x_pos, y_pos, tiles_size, color)
                    app.ctx.draw_square_empty(x_pos, y_pos, tiles_size, gx.black)
                }
            }
        }
    }
}

fn (app App) gun_render(transparence u8){
    color := gx.Color{200, 0, 0, transparence}
    for coos in app.player_gun{
        x_pos := coos[0]*tiles_size + win_width/2    - tiles_size/2
        y_pos := coos[1]*tiles_size + win_height/2   - tiles_size/2

        app.ctx.draw_square_filled(x_pos, y_pos, tiles_size, color)
    }
}

fn on_event(e &gg.Event, mut app App){
    coo_player_relative := [(e.mouse_x - e.window_width/2), (e.mouse_y - e.window_height/2)]
    match e.typ {
        .key_down {
            match e.key_code {
                .escape {app.ctx.quit()}
                .enter{
                    if app.host && !app.game{
                        http.get(serv_url + 'phareouest/start/'  + app.player_key) or {panic(err)}
                    }
                }
                .right{
                    if app.game && app.player_is_alive{
                        http.get(serv_url + 'phareouest/' + app.player_name + '/action/right') or {panic(err)}
                        app.player_pos_x += 1
                    }
                }
                .left{
                    if app.game && app.player_is_alive{
                        http.get(serv_url + 'phareouest/' + app.player_name + '/action/left') or {panic(err)}
                        app.player_pos_x -= 1
                    }
                }
                .down{
                    if app.game && app.player_is_alive{
                        http.get(serv_url + 'phareouest/' + app.player_name + '/action/down') or {panic(err)}
                        app.player_pos_y += 1
                    }
                }
                .up{
                    if app.game && app.player_is_alive{
                        http.get(serv_url + 'phareouest/' + app.player_name + '/action/up') or {panic(err)}
                        app.player_pos_y -= 1
                    }
                }
                else {}
            }
        }
        .mouse_down{
            match e.mouse_button{
                .left{
                    println('Left')
                    for index, pos_tir in app.player_gun{
                        x := coo_player_relative[0] - pos_tir[0]*tiles_size
                        y := coo_player_relative[1] - pos_tir[1]*tiles_size
                        if click_is_in_cube_center(x, y, tiles_size){
                            http.get(serv_url + 'phareouest/' + app.player_name + '/action/shoot/${index}') or {panic(err)}
                            println('/action/shoot/${index}')
                        }
                    }
                }
                else{}
            }
        }
        else {}
    }
}

fn click_is_in_cube_center(x f32, y f32, arrete f64) bool{
	if x <= arrete && x >= -arrete{
        if y <= arrete && y >= -arrete{
		    return true
        }
	}
	else {
		return false
	}
    return false
}
