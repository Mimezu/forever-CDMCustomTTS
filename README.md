# CDM Custom TTS — Forever

Local port of retail 0.4.0 for WoW Forever (interface 16001). Settings are
stored in the native SavedVariables file `CDMCustomTTSDB`.

Hear the alert you need instead of the full spell name.

CDM Custom TTS adds custom spoken text to World of Warcraft's built-in
Cooldown Manager. It works directly inside Blizzard's alert editor, so you can
replace a long spell announcement with a short, instantly recognizable phrase.

For example, **Dream Breath** can simply say **Dream**, while an important buff
can say **Buff ending** shortly before you need to react.

## What you can do

- Write a custom phrase for each Cooldown Manager sound alert
- Choose from the text-to-speech voices available to World of Warcraft
- Preview the phrase and voice before saving
- Use different phrases for different alert events
- Delay aura announcements when you want a reminder later
- Keep using Blizzard's familiar Cooldown Manager interface

CDM Custom TTS is lightweight, standalone, and has no addon dependencies.

## Install

Copy the folder to `World of Warcraft/_forever_/Interface/AddOns/`. Type
`/reload` to discover it; restart the client if it does not appear. Keep the
Forever TOC when updating from retail.

The finished folder should be named `CDMCustomTTS`.

## Create a custom spoken alert

1. Open Blizzard's **Cooldown Manager** settings.
2. Add a new alert or select one you already use.
3. Set **Type** to **Sound**.
4. Set **Sound Alert** to **Text to Speech**.
5. Enter your phrase under **Custom spoken text**.
6. Choose a voice and use **Preview** to hear it.
7. Select **Apply Changes**.

Your normal Cooldown Manager alert will now speak the shorter phrase you chose.

## Delayed aura reminders

For **On Aura Applied** and **On Aura Removed** alerts, you can enter a delay in
seconds. The phrase will play after that amount of time instead of immediately.

This is useful for fixed-duration effects. If a buff normally lasts 18 seconds,
for example, a 14-second delay can remind you that it is about to end.

The delay is a simple timer. If the aura is refreshed, extended, or removed
early, the original timer does not automatically move with it.

## Volume

CDM Custom TTS uses World of Warcraft's text-to-speech audio. Its volume is
controlled by the game's text-to-speech volume setting.

## Compatibility

This port targets WoW Forever's built-in Cooldown Manager. Its alert editor
and speech API match the retail addon. Other Classic clients are not covered
by this port.

`/cdmtts` lists your custom lines; `/cdmtts clear` removes them all.

Created by **Mimezu**.
