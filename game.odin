package game

import "core:fmt"
import rl "vendor:raylib"
import "core:math/rand"
import "core:math"

//clicker code below
characters: rl.Texture
// slots code below
Slots :: enum int {
    SKULL=0,
    BLUEPOTION=1,
    SWORD=2,
    BEER=3,
    WIZARD=4,
    SAPPHIRE=5
}
slots_mult :: [6]f64{0.2,0.3,0.4,0.8,1.0,2.0}
slots_chance:: [6]i64{-1,40,50,80,90,95} // get above

max_lock_time:f64 : 0.9

starting_debt :: 2000000
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
  num_sacrificed_text_pos: Position,
  current_character_x: int,
  current_character_y: int,
  // slots code below
  slots: [3]int,
  current_slot:int,
  slot_textures: [6]rl.Texture2D,
  game_fount:rl.Font,
  lock_machine:bool,
  started_lock:f64,
  roll_offset:[6]f32,
  buyin: int,
  buyin_mult: f32,
  player_coins: int,
  first_calc: bool,
  show_win: bool,
  amount_won: int,
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

  g_mem.game_fount = rl.LoadFont("")

  for i :=0;i<len(g_mem.roll_offset);i+=1 {
    g_mem.roll_offset[i] = auto_cast(i)* 128.0

  }


  g_mem.buyin = 1
  g_mem.player_coins = 5
  g_mem.buyin_mult = 0.5
  g_mem.first_calc = false
  g_mem.show_win = false


  rand.reset(1)
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
    debit_string := fmt.ctprintf("Debit: %d",starting_debt)
    //clicker code below
    rl.DrawTexturePro(characters, g_mem.sacrifice_texture_rect, g_mem.sacrifice_pos_rect, {0, 0}, 0, rl.WHITE)
    sacrificed_text := fmt.ctprintf("Number of sacrifices:\n%d", g_mem.num_sacrificed)
    rl.DrawText(sacrificed_text, g_mem.num_sacrificed_text_pos.x, g_mem.num_sacrificed_text_pos.y, 36, rl.BLACK)

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
    rl.DrawText(debit_string,500,500,20,{0,0,0,255})
    rl.DrawText(coins_string, 500, 530, 20, rl.BLACK)
    rl.DrawText(buyin_string, 500, 560, 20, rl.BLACK)

    if g_mem.show_win {
        rl.DrawText(win_string, 180, 400, 35, rl.BLACK)
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
    g_mem.amount_won = g_mem.buyin * g_mem.slots[0] + g_mem.buyin * g_mem.slots[1] + g_mem.buyin * g_mem.slots[2]
    g_mem.player_coins += g_mem.amount_won
     fmt.printf("Amount won: %d\n", g_mem.amount_won)

}
