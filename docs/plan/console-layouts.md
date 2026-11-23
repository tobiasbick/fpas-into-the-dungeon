# Console layouts

The FPAS TUI keeps the command input and status bar fixed at the bottom. The LLM game master replies above them. While a reply is pending, the status bar reads `Game master is writing` and still shows `F10 Exit`.

All four mockups show the same moment. The player has taken an axe and is typing `go left`.

## 1. Full-width scene

A large room illustration sits above the latest exchange, with the room name in the frame. Leaving the room replaces the illustration.

```text
+- Brass Pump Room --------------------------------------------------+
|                                                                    |
|          .---------.                 ___||___                      |
|         /           \          =====|   ()   |                     |
|        |             |              |  PUMP  |                     |
|        |             |              |________|       j             |
|   _____|             |______________________________               |
|          LEFT ARCH                                                 |
|                                                                    |
+--------------------------------------------------------------------+
| > take the axe                                                     |
| You lift the axe from its hook. Water drips beyond the arch        |
| to your left.                                                      |
+--------------------------------------------------------------------+
| > go left_                                                         |
+--------------------------------------------------------------------+
| Ready                                                     F10 Exit |
+--------------------------------------------------------------------+
```

## 2. Room and adventure log

The current room stays in view on the left while recent commands and replies scroll on the right.

```text
+- Brass Pump Room ------------+- Adventure log ---------------------+
|                              |  > look                             |
|      .---.     ___||___      |  A brass pump shudders. An axe      |
|     /     \===|   ()   |     |  hangs on the far wall.             |
|    |       |  |__PUMP__|     |                                     |
|  __|       |_____________    |  > take the axe                     |
|    Left arch                 |  You lift the axe from its hook.    |
|                              |  Water drips beyond the left arch.  |
+--------------------------------------------------------------------+
| > go left_                                                         |
+--------------------------------------------------------------------+
| Ready                                                     F10 Exit |
+--------------------------------------------------------------------+
```

## 3. Map and narration

A compact ASCII map at the top marks your location and shows known routes. The narration below still has the full width.

```text
+- Brass Pump Room --------------------------------------------------+
|                       [Storage]                                    |
|                           |                                        |
|  Left arch  [?]--------- [@]--------- [Stairs]                     |
|                                                                    |
|  @ You    ? Unexplored                                             |
+--------------------------------------------------------------------+
| > take the axe                                                     |
| You lift the axe from its hook. The pump rattles behind you.       |
| Water drips beyond the unexplored arch to your left.               |
+--------------------------------------------------------------------+
| > go left_                                                         |
+--------------------------------------------------------------------+
| Ready                                                     F10 Exit |
+--------------------------------------------------------------------+
```

## 4. Illustrated transcript

Commands, replies and room sketches scroll together. A sketch appears when you enter a room and stays with that turn in the log.

```text
+- Adventure log ----------------------------------------------------+
| > go down the stairs                                               |
| You enter the Brass Pump Room. Pipes shake above your head.        |
|                                                                    |
|         /-----\      ___||___                                      |
|        |       |====|   ()   |       j                             |
|   _____|       |____|__PUMP__|_______                              |
|                                                                    |
| > take the axe                                                     |
| You lift the axe from its hook. Water drips beyond the arch        |
| to your left.                                                      |
+--------------------------------------------------------------------+
| > go left_                                                         |
+--------------------------------------------------------------------+
| Ready                                                     F10 Exit |
+--------------------------------------------------------------------+
```
