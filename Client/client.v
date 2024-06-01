import gg
import net.http {get}

const win_width    = 601
const win_height   = 601
const bg_color     = gg.Color{}

const serv_url     = "http://93.23.133.25:8100/"



struct App {
mut:
    gg    &gg.Context = unsafe { nil }
    

    player_name     string
    player_key      string

    host            bool    = false
    game			bool    = false
    
    tiles_size      int     = 10
    world_map       []string
}


fn main() {
    mut app := &App{}
    app.gg = gg.new_context(
        width: win_width
        height: win_height
        create_window: true
        window_title: '- Application -'
        user_data: app
        bg_color: bg_color
        frame_fn: on_frame
        event_fn: on_event
        sample_count: 2
    )

    //lancement du programme/de la fenêtre
    app.gg.run()
}

fn on_frame(mut app App) {
    //
    if app.game{

    }
    else if app.player_key == ""{
        res         := http.get(serv_url + "phareouest/po") or {http.Response{}}
        res_body    := res.body.split('/')
        app.player_key = res_body[0]
        if res.body.len == 2{
            app.host = true
        }
    }
    else{
        res         := http.get(serv_url + "phareouest/wait_start") or {http.Response{}}
        res_body    := res.body.split('/')
        nb_player   := res_body[0]
        println(nb_player)
        if res_body[1] == "true"{
            app.game = true
            res_map := http.get(serv_url + "phareouest/map") or {http.Response{}}
            mut map_tempo := res_map.body.split(', ')
            map_tempo[0] = map_tempo[0][1..]
            map_tempo[map_tempo.len - 1] = map_tempo[map_tempo.len - 1][..map_tempo[map_tempo.len - 1].len - 1]
            app.world_map
        }
    }
}

fn on_event(e &gg.Event, mut app App){
    match e.typ {
        .key_down {
            match e.key_code {
                .escape {app.gg.quit()}
                .enter{
                    if app.host{
                        http.get(serv_url + "phareouest/start") or {http.Response{}}
                    }
                }
                .right{
                    if app.game{
                        res := http.get(serv_url + "phareouest/" + app.player_name + "/action/right") or {http.Response{}}
                        print(res)
                    }
                }
                .left{
                    if app.game{
                        res := http.get(serv_url + "phareouest/" + app.player_name + "/action/left") or {http.Response{}}
                        print(res) 
                    }
                }
                .down{
                    if app.game{
                        res := http.get(serv_url + "phareouest/" + app.player_name + "/action/down") or {http.Response{}}
                        print(res)
                    }
                }
                .up{
                    if app.game{
                        res := http.get(serv_url + "phareouest/" + app.player_name + "/action/up") or {http.Response{}}
                    print(res)
                    }
                }
                else {}
            }
        }
        else {}
    }
}