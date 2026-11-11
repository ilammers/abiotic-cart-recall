# Installing Cart Return

This guide assumes you've never modded a game before. It takes about 10 minutes
the first time. Updating later takes about 1 minute.

You will:

1. Find the game's folder
2. Install **UE4SS**, the tool that lets the game run mods (one time only)
3. Install **Cart Return**
4. Check that it worked

Close Abiotic Factor before you start.

---

## Before you start: show file extensions

Windows hides the end of file names (`.txt`, `.dll`, `.zip`) by default, which
makes the steps below harder to follow. To turn that off:

- **Windows 11:** open any folder, click **View** → **Show** → **File name extensions**.
- **Windows 10:** open any folder, click the **View** tab and tick **File name extensions**.

---

## Step 1: Find the game folder

You need the folder that contains the file **`AbioticFactor-Win64-Shipping.exe`**.
This guide calls it **the game folder**.

### Steam

1. Open Steam and go to your **Library**.
2. Right-click **Abiotic Factor** → **Manage** → **Browse local files**.
   A folder window opens.
3. Open **`AbioticFactor`** → **`Binaries`** → **`Win64`**.
4. You should see `AbioticFactor-Win64-Shipping.exe` in this folder. If you do,
   this is the game folder. Leave the window open.

On most PCs this is:

```
C:\Program Files (x86)\Steam\steamapps\common\AbioticFactor\AbioticFactor\Binaries\Win64
```

### Xbox app / PC Game Pass

The folder ends in **`WinGDK`** instead of `Win64`, and is usually:

```
C:\XboxGames\Abiotic Factor\Content\AbioticFactor\Binaries\WinGDK
```

Everywhere this guide says `Win64`, use `WinGDK` instead.

---

## Step 2: Install UE4SS (one time only)

UE4SS is a free tool that lets the game load script mods like this one.
Abiotic Factor needs a specific build of it.

1. Go to the **AF-UE4SS releases page**:
   <https://github.com/igromanru/AF-UE4SS/releases>
2. Under the newest release (the one at the top), click **Assets** if it isn't
   already open, then download the zip whose name ends in
   **`_Abiotic_Factor.zip`**. Don't download the one ending in `Debug.Symbols.zip`.

   The same bundle is also on Nexus Mods:
   <https://www.nexusmods.com/abioticfactor/mods/35>
3. Find the zip in your **Downloads** folder. Right-click it → **Extract All…** →
   **Extract**.
4. Open the extracted folder. It contains two things:
   - a file called **`dwmapi.dll`**
   - a folder called **`ue4ss`**
5. Select both, copy them (**Ctrl+C**), go to the game folder from Step 1 and
   paste them (**Ctrl+V**). If Windows asks to replace files, click
   **Replace the files in the destination**.

The game folder should now contain these, side by side:

```
Win64\
  AbioticFactor-Win64-Shipping.exe
  dwmapi.dll
  ue4ss\
```

> `dwmapi.dll` must be next to the `.exe`, not inside the `ue4ss` folder.

---

## Step 3: Install Cart Return

1. Go to the Cart Return **Releases** page (on this repository's GitHub page,
   click **Releases** on the right-hand side).
2. Under the newest release, download **`CartReturn-v….zip`**.

   > Don't use the green **Code → Download ZIP** button. That gives you the
   > source files in the wrong layout.
3. Right-click the zip → **Extract All…** → **Extract**.
4. Inside the extracted folder is a folder called **`CartReturn`**. Copy it.
5. In the game folder, open **`ue4ss`** → **`Mods`** and paste `CartReturn` there.

It should end up like this:

```
Win64\
  ue4ss\
    Mods\
      CartReturn\
        enabled.txt
        Scripts\
          main.lua
```

Check that the folder is `Mods\CartReturn\Scripts`. It should **not** be
`Mods\CartReturn\CartReturn\Scripts`. If you have a doubled folder, move the
inner `CartReturn` up one level.

---

## Step 4: Check that it worked

1. Start Abiotic Factor and load into a world.
2. Quit the game.
3. In the game folder, open **`ue4ss`** and open the file **`UE4SS.log`** (it
   opens in Notepad).
4. Press **Ctrl+F** and search for **`CartReturn`**. You should find a line like:

   ```
   [CartReturn] v1.2.0 loaded. F6: nearest cart, F7: all carts, F8: scan, F9: empty carts at feet.
   ```

If it's there, the mod is working.

---

## Using it

In-game, while in a world:

| Key | What it does |
| --- | --- |
| **F6** | Brings the nearest Platform Cart to just in front of you |
| **F7** | Brings **all** your Platform Carts, lined up in front of you |
| **F8** | Diagnostic scan. Only needed if something isn't working |
| **F9** | Empties **all** your carts into loot bags at your feet, the same way the game's recall button does. The empty carts go back to where they spawn. |

Whatever is inside a cart stays inside it.

**Playing with friends:** the **host** (the person whose world it is) needs to
have the mod installed and press the keys. If someone who joined presses them,
other players may not see the carts move.

---

## Updating

### When a new version of Cart Return comes out

1. Close the game.
2. Go to `ue4ss\Mods` in the game folder and **delete** the old `CartReturn` folder.
3. Do [Step 3](#step-3-install-cart-return) again with the new download.

You don't need to reinstall UE4SS.

### When Abiotic Factor itself gets a big update

Game updates sometimes break UE4SS. Signs: the game crashes on start, or
`CartReturn` no longer appears in `UE4SS.log`.

1. Wait for a new AF-UE4SS release that supports the new game version. It
   usually appears within a few days.
2. Do [Step 2](#step-2-install-ue4ss-one-time-only) again with the new download,
   and click **Replace** when asked.

Replacing files this way keeps Cart Return installed. **Don't delete** the old
`ue4ss` folder first, because that also deletes your mods.

---

## Problems

**Pressing F6/F7 does nothing.**
Open `UE4SS.log` (see Step 4) and search for `CartReturn`.

- **No `CartReturn` lines at all:** the mod isn't loading. Check the folder
  layout in Step 3, and that `dwmapi.dll` is next to the `.exe` (Step 2).
- **"No carts found":** the mod doesn't recognise the cart in this game version.
  Stand next to a Platform Cart, press **F8**, quit the game, and send the
  `UE4SS.log` file to the mod author or attach it to a GitHub issue. Nothing
  needs editing on your end.

**The game crashes when loading in, going to the main menu or quitting.**
This is a known UE4SS issue with Abiotic Factor and usually doesn't affect your
game or saves. If it crashes every time on start, see
[When Abiotic Factor itself gets a big update](#when-abiotic-factor-itself-gets-a-big-update).

**Windows says it can't find `UE4SS.log`.**
UE4SS isn't installed in the right place. Redo Step 2 and make sure
`dwmapi.dll` and the `ue4ss` folder are in the same folder as
`AbioticFactor-Win64-Shipping.exe`.

---

## Uninstalling

- **Just this mod:** delete `ue4ss\Mods\CartReturn`.
- **All mods:** delete `dwmapi.dll` and the `ue4ss` folder from the game folder.
  Steam → right-click the game → **Properties** → **Installed Files** →
  **Verify integrity of game files** puts everything back to normal.
