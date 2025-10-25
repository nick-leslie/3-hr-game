package game

import "core:fmt"
import rl "vendor:raylib"
import "core:math/rand"

//clicker code below

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

/* Our game's state lives within this struct. In
order for hot reload to work the game's memory
must be transferable from one game DLL to
another when a hot reload occurs. We can do that
when all the game's memory live in here. */
GameMemory :: struct {
  some_state: int,
  //clicker code below

  // slots code below
  slots: [3]int,
  current_slot:int,
  slot_textures: [6]rl.Texture2D,
  lock_machine:bool,
  started_lock:f64
}

g_mem: ^GameMemory

/* Allocates the GameMemory that we use to store
our game's state. We assign it to a global2
variable so we can use it from the other
procedures. */
@(export)
game_init :: proc() {
  g_mem = new(GameMemory)
  rl.InitWindow(1280, 720, "My Odin + Raylib game")
  //clicker code below

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


  rand.reset(1)
}

/* Simulation and rendering goes here. Return
false when you wish to terminate the program. */
@(export)
game_update :: proc() -> bool {
  g_mem.some_state += 1
  // fmt.println(g_mem.some_state)
  //clicker code below

  // slots code below

  if rl.IsKeyPressed(.SPACE) && g_mem.lock_machine == false {
      do_roll()
  }

  if g_mem.lock_machine == true {
      if rl.GetTime() - g_mem.started_lock >= max_lock_time {
          rest_machine()
      }
  }

  draw_game()
  return !rl.WindowShouldClose()
}

draw_game :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground({160, 200, 255, 255})
    //clicker code below

    // slots code below
    debit_string := fmt.ctprintf("Debit: %d",starting_debt)

    for i := 0; i< len(g_mem.slots);i+=1 {
        slot_val := g_mem.slots[i]
        if(slot_val == -1) {
            // draw rolling animation
        } else {
            rl.DrawTexturePro(g_mem.slot_textures[slot_val],{0,0,32,32},{150+ auto_cast(i* 128),250,128,128},{128/2,128/2},0.0,rl.WHITE)
        }
    }

    rl.DrawText(debit_string,500,500,20,{0,0,0,255})
    rl.EndDrawing()

    free_all(context.temp_allocator)
}

/* Called by the main program when the main loop
has exited. Clean up your memory here. */
@(export)
game_shutdown :: proc() {
  rl.CloseWindow()
  //clicker code below

  // slots code below
  for i := 0; i< len(g_mem.slot_textures);i+=1 {
      rl.UnloadTexture(g_mem.slot_textures[i])
  }
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

// slots code below

do_roll :: proc() {
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
    }
}

rest_machine :: proc() {
    g_mem.lock_machine = false
    g_mem.started_lock = 0.0 // restart the timer
    g_mem.current_slot = 0
    for i := 0 ; i<len(g_mem.slots);i+=1 {
        g_mem.slots[i] = -1
    }
}

calculate_win :: proc() {

}
