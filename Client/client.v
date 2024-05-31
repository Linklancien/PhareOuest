import gg
import net.http {get}

const win_width    = 601
const win_height   = 601
const bg_color     = gg.Color{}

const serv_url     = "http://93.23.133.25:8100/"



struct App {
mut:
    gg    &gg.Context = unsafe { nil }
    square_size int = 10
    mut:
        player_name =   string
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
    //Draw
    app.gg.begin()
    app.gg.draw_square_filled(0, 0, app.square_size, gg.Color{255, 0, 0, 255}) // couleurs en rgba
    app.gg.end()
}

fn on_event(e &gg.Event, mut app App){
    match e.typ {
        .key_down {
            match e.key_code {
                .escape {app.gg.quit()}
                .right{
                    repons := http.get(serv_url + "phareouest/" + app.player_name "/action/right") or {http.Response{}}
                    print(repons)
                }
                .left{
                    repons := http.get(serv_url + "phareouest/" + app.player_name "/action/left") or {http.Response{}}
                    print(repons)
                }
                .down{
                    repons := http.get(serv_url + "phareouest/" + app.player_name "/action/down") or {http.Response{}}
                    print(repons)
                }
                .up{
                    repons := http.get(serv_url + "phareouest/" + app.player_name "/action/up") or {http.Response{}}
                    print(repons)
                }
                else {}
            }
        }
        else {}
    }
}