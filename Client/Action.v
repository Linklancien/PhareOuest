import gg
import gx
import net.http { get }

const actions_names = ["None", "Quit the game", "Start the game", "pause", "move down", "move up", "move right", "move left"]
const boutons_radius = 10
const boutons_radius_square = boutons_radius*boutons_radius

enum Actions {
	no				= 0
	quit			= 1
	start			= 2
	pause			= 3

	move_down		= 4
	move_up			= 5
	move_right		= 6
	move_left		= 7	
}

const key_code_name := {
	0	: ""
	32	: "space"
	39	: "apostrophe"
	44	: "comma"	//,
	45	: "minus"	//-
	46	: "period"	//.
	47	: "slash"
	48	: "0"
	49	: "1"
	50	: "2"
	51	: "3"
	52	: "4"
	53	: "5"
	54	: "6"
	55	: "7"
	56	: "8"
	57	: "9"
	59	: "semicolon"	//;
	61	: "equal" 		//:
	65	: "a"
	66	: "b"
	67	: "c"
	68	: "d"
	69	: "e"
	70	: "f"
	71	: "g"
	72 	: "h"
	73	: "i"
	74	: "j"
	75	: "k"
	76	: "l"
	77	: "m"
	78	: "n"
	79	: "o"
	80	: "p"
	81	: "q"
	82	: "r"
	83	: "s"
	84	: "t"
	85	: "u"
	86	: "v"
	87	: "w"
	88	: "x"
	89	: "y"
	90	: "z"
	91	: "left_bracket"	//[
	92	: "backslash"		//\
	93	: "right_bracket"	//]
	96	: "grave_accent"	//`
	161	: "world_1"			// non-us #1
	162 : "world_2"			// non-us #2
	256	: "escape"
	257 : "enter"
	258	: "tab"
	259	: "backspace"
	260	: "insert"
	261	: "delete"
	262	: "right"
	263	: "left"
	264	: "down"
	265	: "up"
	266 : "page_up"
	267	: "page_down"
	268 : "home"
	269	: "end"
	280 : "caps_lock"
	281	: "scroll_lock"
	282	: "num_lock"
	283	: "print_screen"
	284	: "pause"
	290	: "f1"
	291	: "f2"
	292	: "f3"
	293	: "f4"
	294	: "f5"
	295	: "f6"
	296	: "f7"
	297	: "f8"
	298	: "f9"
	299	: "f10"
	300	: "f11"
	301	: "f12"
	302	: "f13"
	303	: "f14"
	304 : "f15"
	305 : "f16"
	306	: "f17"
	307	: "f18"
	308	: "f19"
	309	: "f20"
	310	: "f21"
	311	: "f22"
	312	: "f23"
	313	: "f24"
	314	: "f24"
	320	: "kp_0"
	321	: "kp_1"
	322	: "kp_2"
	323	: "kp_3"
	324	: "kp_4"
	325	: "kp_5"
	326	: "kp_6"
	327	: "kp_7"
	328	: "kp_8"
	329	: "kp_9"
	330	: "kp_decimal"
	331	: "kp_divide"
	332	: "kp_multiply"
	333	: "kp_subtract"
	334	: "kp_add"
	335	: "kp_enter"
	336	: "kp_equal"
	340 : "left_shift"
	341	: "left_control"
	342	: "left_alt"
	343	: "left_super"
	344	: "right_shift"
	345	: "right_control"
	346	: "right_alt"
	347	: "right_super"
	348	: "menu"
}

fn (mut app App) list_imput_action_key_code_init(){
	// 348
	app.list_imput_action = []Actions{len: 348, init: Actions.no}
	app.list_action_key_code = []int{len: actions_names.len, init: 0}

	// Quit
	app.list_imput_action[int(gg.KeyCode.f4)] = Actions.quit

	app.list_action_key_code[Actions.quit] = int(gg.KeyCode.f4)

	// Start
	app.list_imput_action[int(gg.KeyCode.enter)] = Actions.start
	app.list_action_key_code[Actions.start] = int(gg.KeyCode.enter)

	// Pause
	app.list_imput_action[int(gg.KeyCode.escape)] = Actions.pause
	app.list_action_key_code[Actions.pause] = int(gg.KeyCode.escape)
	///////////////////////////////////////////////////////////////////////////////////////
	mut down	:= int(gg.KeyCode.down)
	mut up		:= int(gg.KeyCode.up)
	mut right	:= int(gg.KeyCode.right)
	mut left	:= int(gg.KeyCode.left)
	// Déplacements
	app.list_imput_action[down]		= Actions.move_down
	app.list_imput_action[up]		= Actions.move_up
	app.list_imput_action[right]	= Actions.move_right
	app.list_imput_action[left]		= Actions.move_left

	app.list_action_key_code[4] = down
	app.list_action_key_code[5] = up
	app.list_action_key_code[6] = right
	app.list_action_key_code[7] = left
}

fn (mut app App) settings_render(){
	for ind in 1..10{
		if ind + app.pause_scroll < actions_names.len {
			x := int(win_width/2)
			y := int(100 + ind * 40)
			app.text_rect_render(x, y, (actions_names[ind + app.pause_scroll] + ": " + key_code_name[app.list_action_key_code[ind + app.pause_scroll]]), 255)

			x2 := int(3*win_width/4)
			app.ctx.draw_circle_filled(x2, y + 15, boutons_radius, gx.gray)
		}
	}
}

// Actions
fn (mut app App) pause_check_boutons(mouse_x f32, mouse_y f32){
	// Check
	x_square := (3*win_width/4 - mouse_x)*(3*win_width/4 - mouse_x)
	pre_y := 115 - mouse_y
	for ind in 1..10{
		if ind + app.pause_scroll < actions_names.len {
			y := pre_y + ind * 40 
			
			if x_square + y*y < boutons_radius_square{
				app.imput_action_change = unsafe{Actions(ind + app.pause_scroll)}
				break
			}
		}
	}
}

fn (mut app App) imput(index int){
	if app.imput_action_change == Actions.no{
		app.imput_action(index)
	}
	else{
		// Change old
		// Set the old imput for the changing action to no
		index_old_key	:= app.list_action_key_code[int(app.imput_action_change)]
		app.list_imput_action[index_old_key] = Actions.no
		// Set the old action linked to the imput (index) to 0
		old_action := app.list_imput_action[index]
		app.list_action_key_code[int(old_action)] = 0


		// New
		// Change to match the imput with what action it do
		app.list_imput_action[index] = app.imput_action_change
		// Change to match action to what is the imput that triger it
		app.list_action_key_code[int(app.imput_action_change)] = index

		// Reset imput_action_change
		app.imput_action_change = Actions.no
	}
}

fn (mut app App) imput_action(index int){
	match app.list_imput_action[index]{
		.quit {
			app.ctx.quit()
		}
		.start {
			if app.host && !app.game {
				get(serv_url + 'phareouest/start/' + app.player_key) or { panic(err) }
			}
		}
		.pause{
			app.pause_scroll = 0
			app.pause = !app.pause
		}
		.move_right {
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
		.move_left {
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
		.move_down {
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
		.move_up {
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
		else{}
	}
	
}

// Others fonctions
fn (app App) text_rect_render(x int, y int, text string, transparence u8){
	lenght := text.len * 8 + 10
	new_x := x - lenght/2
	new_y := y
	app.ctx.draw_rounded_rect_filled(new_x, new_y, lenght, app.text_cfg.size + 10, 5, attenuation(gx.gray, transparence))
	app.ctx.draw_text(new_x + 5, new_y + 5, text, app.text_cfg)
}

fn attenuation (color gx.Color, new_a u8) gx.Color{
	return gx.Color{color.r, color.g, color.b, new_a}
}

