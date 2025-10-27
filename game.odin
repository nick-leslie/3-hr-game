package game

import "core:fmt"
import rl "vendor:raylib"
import "core:math/rand"
import "core:math"

//clicker code below
characters: rl.Texture
pentagram: rl.Texture
// slots code below
Slots :: enum int {
    SKULL=0,
    BLUEPOTION=1,
    SWORD=2,
    BEER=3,
    WIZARD=4,
    SAPPHIRE=5
}
slots_mult :: [6]f64{1.4,1.9,2.0,2.5,3.0,5.0}
slots_chance:: [6]i64{-1,30,40,50,65,80} // get above

max_lock_time:f64 : 0.9

starting_debt :: 2000
spin_speed :f32:1000
/* Our game's state lives within this struct. In
order for hot reload to work the game's memory
must be transferable from one game DLL to
another when a hot reload occurs. We can do that
when all the game's memory live in here. */
GameMemory :: struct {
  some_state: int,
  //clicker code below
  num_sacrificed: int,
  sacrifice_pos_rect: rl.Rectangle,
  sacrifice_texture_rect: rl.Rectangle,
  num_sacrificed_text_pos: rl.Vector2,
  current_character_x: int,
  current_character_y: int,
  // slots code below
  slots: [3]int,
  current_slot:int,
  slot_textures: [6]rl.Texture2D,
  game_font:rl.Font,
  lock_machine:bool,
  started_lock:f64,
  roll_offset:[6]f32,
  buyin: int,
  buyin_mult: f32,
  player_coins: int,
  first_calc: bool,
  show_win: bool,
  amount_won: int,
  debit: int,
  debit_dif: f32,
}

g_mem: ^GameMemory

Position :: struct {
    x: i32,
    y: i32
}

/* Allocates the GameMemory that we use to store
our game's state. We assign it to a global2
variable so we can use it from the other
procedures. */
@(export)
game_init :: proc() {
  g_mem = new(GameMemory)
  rl.InitWindow(1280, 720, "Lets go gambling!")
  //clicker code below
  // Set initial values
  g_mem.num_sacrificed = 0
  g_mem.sacrifice_pos_rect = {1000, 360, 100, 100}
  g_mem.sacrifice_texture_rect = {0, 0, 32, 32}
  g_mem.num_sacrificed_text_pos = {800, 290}
  // Load in the character
  characters = rl.LoadTexture("assets/32rogues/rogues.png")
  pentagram = rl.LoadTexture("assets/Pentagram.png")


  // slots code below
  g_mem.slots[0] = -1
  g_mem.slots[1] = -1
  g_mem.slots[2] = -1
  g_mem.current_slot = 0
  g_mem.slot_textures[0] = rl.LoadTexture("assets/Skull.png")
  g_mem.slot_textures[1] = rl.LoadTexture("assets/Blue_Potion.png")
  g_mem.slot_textures[4] = rl.LoadTexture("assets/Sword.png")
  g_mem.slot_textures[2] = rl.LoadTexture("assets/Beer.png")
  g_mem.slot_textures[3] = rl.LoadTexture("assets/Wizard_Hat.png")
  g_mem.slot_textures[5] = rl.LoadTexture("assets/Sapphire.png")

  g_mem.game_font = rl.LoadFont("assets/dungeon-mode.ttf")

  for i :=0;i<len(g_mem.roll_offset);i+=1 {
    g_mem.roll_offset[i] = auto_cast(i)* 128.0

  }


  g_mem.buyin = 1
  g_mem.player_coins = 5
  g_mem.buyin_mult = 0.5
  g_mem.first_calc = false
  g_mem.show_win = false
  g_mem.debit = starting_debt

  // rand.reset(1)
}

/* Simulation and rendering goes here. Return
false when you wish to terminate the program. */
@(export)
game_update :: proc() -> bool {
  g_mem.some_state += 1
  // fmt.println(g_mem.some_state)
  //clicker code below
  character_clicked()


  // slots code below


  // slots code below
  g_mem.buyin = cast(int) math.ceil(f64(g_mem.buyin_mult) * f64(g_mem.num_sacrificed))
  g_mem.buyin = max(g_mem.buyin, 1)

  ratio := f32(g_mem.player_coins) / f32(g_mem.debit);

  if ratio >= 1.0 {
      // how much above the debt you are, relative to debt
      g_mem.debit_dif = (ratio - 1.0) * 100.0;         // 159/100 -> 59%
  } else {
      // how much below the debt you are, relative to debt
      g_mem.debit_dif = (1.0 - ratio) * 100.0;
  }

  if rl.IsKeyPressed(.SPACE) && g_mem.lock_machine == false {
      do_roll()
  }

  if g_mem.lock_machine == true {

      //Calculate win single time here
      if g_mem.first_calc {
          calculate_win() //debug
          g_mem.first_calc = false
      }


      if rl.GetTime() - g_mem.started_lock >= max_lock_time {
          g_mem.show_win = false
          rest_machine()
      }
  }

  draw_game()
  return !rl.WindowShouldClose()
}

draw_game :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground({160, 200, 255, 255})

    // slots code below
    debit_string := fmt.ctprintf("Debit: %d",g_mem.debit)
    //clicker code below
    rl.DrawTexturePro(pentagram,{0,0,16,16},{1000-50, 360-50, 200, 200}, {0, 0}, 0, rl.WHITE)
    rl.DrawTexturePro(characters, g_mem.sacrifice_texture_rect, g_mem.sacrifice_pos_rect, {0, 0}, 0, rl.WHITE)
    sacrificed_text := fmt.ctprintf("Number of sacrifices:\n%d", g_mem.num_sacrificed)
    rl.DrawTextEx(g_mem.game_font, sacrificed_text, g_mem.num_sacrificed_text_pos, 23, 0, rl.BLACK)

    for i := 0; i< len(g_mem.slots);i+=1 {
        slot_val := g_mem.slots[i]
        if(slot_val == -1) {
            for j := 0; j<len(g_mem.slot_textures);j+=1 {
                y:f32 =  g_mem.roll_offset[j]
                if g_mem.roll_offset[j] > 750 {
                    y = 0
                    g_mem.roll_offset[j] = 0
                }
                rl.DrawTexturePro(g_mem.slot_textures[j],{0,0,32,32},{150+ auto_cast(i* 128),y,128,128},{128/2,128/2},0.0,rl.WHITE)
            }
        } else {
            rl.DrawTexturePro(g_mem.slot_textures[slot_val],{0,0,32,32},{150+ auto_cast(i* 128),250,128,128},{128/2,128/2},0.0,rl.WHITE)
        }
    }
    for i :=0;i<len(g_mem.roll_offset);i+=1 {
      g_mem.roll_offset[i] += (spin_speed * rl.GetFrameTime())
    }

    rl.DrawRectangle(0,0,700,150,{160, 200, 255, 255})
    rl.DrawRectangleLinesEx({0,0,700,150},5,{0, 0, 0, 255});
    rl.DrawRectangle(0,350,700,500,{160, 200, 255, 255})
    rl.DrawRectangleLinesEx({0,350,700,500},5,{0, 0, 0, 255})
    rl.DrawRectangle(700,0,90,900,{160, 200, 255, 255})
    rl.DrawRectangleLinesEx({700,0,90,900},5,{0, 0, 0, 255})
    coins_string := fmt.ctprintf("Total coins: %d",g_mem.player_coins)
    buyin_string := fmt.ctprintf("Buy-in: %d",g_mem.buyin)
    win_string := fmt.ctprintf("Amount won: %d",g_mem.amount_won)

    debt_dif_string : cstring
    if g_mem.debit_dif > 0 {
        debt_dif_string = fmt.ctprintf("Percent Down: %.f",math.abs(g_mem.debit_dif))
    } else {
        debt_dif_string = fmt.ctprintf("Percent Up: %.f", math.abs(g_mem.debit_dif))
    }

    rl.DrawTextEx(g_mem.game_font, debit_string, {170 ,500}, 20, 0, rl.BLACK)
    rl.DrawTextEx(g_mem.game_font, coins_string, {170, 530}, 20, 0, rl.BLACK)
    rl.DrawTextEx(g_mem.game_font, buyin_string, {170, 560}, 20, 0, rl.BLACK)
    rl.DrawTextEx(g_mem.game_font, debt_dif_string, {170, 590}, 20, 0, rl.BLACK)
    if g_mem.show_win {
        rl.DrawTextEx(g_mem.game_font, win_string, {100, 400}, 35, 2, rl.BLACK)
    }

    rl.EndDrawing()

    free_all(context.temp_allocator)
}

/* Called by the main program when the main loop
has exited. Clean up your memory here. */
@(export)
game_shutdown :: proc() {
    //clicker code below
    rl.UnloadTexture(characters)

  // slots code below
  for i := 0; i< len(g_mem.slot_textures);i+=1 {
      rl.UnloadTexture(g_mem.slot_textures[i])
  }
  rl.CloseWindow()
  free(g_mem)

}

/* Returns a pointer to the game memory. When
to the game memory. It can then load a new game
hot reloading, the main program needs a pointer
hot reloading, the main program needs a pointer
DLL and tell it to use the same memory by calling
game_hot_reloaded on the new game DLL, supplying
it the game memory pointer. */
@(export)
game_memory :: proc() -> rawptr {
  return g_mem
}

/* Used to set the game memory pointer after a
hot reload occurs. See game_memory comments. */
@(export)
game_hot_reloaded :: proc(mem: ^GameMemory) {
  g_mem = mem
}



//clicker code below
character_clicked :: proc() {
    mouse_x := rl.GetMouseX()
    mouse_y := rl.GetMouseY()
    if(!rl.IsMouseButtonPressed(rl.MouseButton.LEFT)){
        return;
    }

    mouse_vec : rl.Vector2 = {auto_cast mouse_x, auto_cast mouse_y}
    if (rl.CheckCollisionPointRec(mouse_vec, g_mem.sacrifice_pos_rect)){
        g_mem.num_sacrificed += 1
        g_mem.current_character_x = auto_cast rl.GetRandomValue(0, 4) * 32
        g_mem.current_character_y = auto_cast rl.GetRandomValue(0, 6) * 32
        g_mem.sacrifice_texture_rect = {auto_cast g_mem.current_character_x, auto_cast g_mem.current_character_y, 32, 32}
    }
}

// slots code below

do_roll :: proc() {

    if g_mem.slots == -1 {
        fmt.printf("Buyin: %d\n", g_mem.buyin)
        g_mem.player_coins -= g_mem.buyin
    }

    n := rand.int63_max(100) + 1 // gives number from 1 to 100
    fmt.printf("roll %d current_slot %d\n", n,g_mem.current_slot)
    fmt.println(g_mem.slots)
    if n >= slots_chance[5] {
        // hit jackpot on section
        g_mem.slots[g_mem.current_slot] = cast(int) Slots.SAPPHIRE // todo convert into enum
    } else if n >= slots_chance[4] {
        g_mem.slots[g_mem.current_slot] = cast(int)Slots.WIZARD
        // rolled 4
    } else if n >= slots_chance[3] {
        g_mem.slots[g_mem.current_slot] =cast(int) Slots.BEER
        // rolled 3
    } else if n >= slots_chance[2] {
        g_mem.slots[g_mem.current_slot] = cast(int)Slots.SWORD
        // rolled 2
    } else if n >= slots_chance[1] {
        g_mem.slots[g_mem.current_slot] =cast(int) Slots.BLUEPOTION
        // rolled 1
    } else {
        g_mem.slots[g_mem.current_slot] =cast(int) Slots.SKULL
        // rolled 0
    }
    fmt.println(g_mem.slots)

    g_mem.current_slot +=1
    if g_mem.current_slot >= len(g_mem.slots){
        g_mem.lock_machine = true
        g_mem.started_lock = rl.GetTime()
        g_mem.first_calc = true
        g_mem.show_win = true
    }
}

rest_machine :: proc() {
    g_mem.lock_machine = false
    g_mem.started_lock = 0.0 // restart the timer
    g_mem.current_slot = 0
    for i := 0 ; i<len(g_mem.slots);i+=1 {
        g_mem.slots[i] = -1
    }
    for i :=0;i<len(g_mem.roll_offset);i+=1 {
      g_mem.roll_offset[i] = auto_cast(i)* 128.0

    }
}

calculate_win :: proc() {
    zero_one_same := g_mem.slots[0] == g_mem.slots[1]
    one_two_same :=  g_mem.slots[1] == g_mem.slots[2]
    zero_two_same := g_mem.slots[0] == g_mem.slots[2]
    mult := slots_mult

    fmt.printf("01:%t,12:%t,02:%t\n",zero_one_same,one_two_same,zero_two_same)
    if zero_one_same && one_two_same && zero_two_same {
        // all three same
        calc := cast(f64)g_mem.buyin * (mult[g_mem.slots[0]] * 2)
        fmt.println(calc)
        g_mem.amount_won = cast(int)math.round(calc)
        if g_mem.amount_won == 0 {
            g_mem.amount_won = 1
        }
    } else if zero_one_same {
        g_mem.amount_won = cast(int)math.round(cast(f64)g_mem.buyin * (mult[g_mem.slots[0]] * 1))
        if g_mem.amount_won == 0 {
            g_mem.amount_won = 1
        }
    } else if one_two_same {
        g_mem.amount_won = cast(int)math.round(cast(f64)g_mem.buyin * (mult[g_mem.slots[1]] * 1))
        if g_mem.amount_won == 0 {
            g_mem.amount_won = 1
        }
    } else if zero_two_same {
        g_mem.amount_won = cast(int)math.round(cast(f64)g_mem.buyin * (mult[g_mem.slots[0]] * 1))
        if g_mem.amount_won == 0 {
            g_mem.amount_won = 1
        }
    } else {
        g_mem.amount_won = 0
    }




    g_mem.player_coins += g_mem.amount_won
    fmt.printf("Amount won: %d\n", g_mem.amount_won)

    if g_mem.player_coins < 0 {
        g_mem.debit += math.abs(g_mem.player_coins) + g_mem.buyin
        g_mem.player_coins += g_mem.buyin
    }
}
