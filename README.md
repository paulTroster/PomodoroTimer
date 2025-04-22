# Pomodoro Timer for OBS

A versatile and fully customizable Pomodoro Timer script built specifically for OBS Studio. This script helps you manage your focus sessions and breaks while streaming or recording, keeping both you and your audience informed about your progress.

<img width="521" alt="Screenshot 2025-04-22 at 21 21 52" src="https://github.com/user-attachments/assets/caafc7e7-2b16-44f5-88d3-4fbb19593ab7" />

---

## What It Does

- **Personalized Timer Intervals:**  
  Configure focus sessions, short breaks, and long breaks to match your workflow.

- **Session Tracking with Auto-Stop:**  
  The timer tracks your completed focus sessions and automatically stops when you reach your preset session limit.

- **Streamlined Controls:**  
  The Start and Stop buttons are prominently placed at the top of the settings panel for quick access.

- **Fast Mode for Testing:**  
  For demo or testing purposes, enable Fast Mode to have time progress 60× faster (1 real second equals 1 minute).

- **Sound Alerts:**  
  A designated OBS media source plays an alert sound during transitions between focus and break periods.

- **Seamless OBS Integration:**  
  The script updates a chosen text source in OBS with live timer data and session counts, ensuring your stream is always up-to-date.

---

## Installation

1. **Download the Script:**  
   Save the `pomodoro.lua` file to your computer.

2. **Launch OBS Studio:**  
   Open OBS and go to **Tools > Scripts**.

3. **Add the Script:**  
   Click the **+** button in the Scripts window and select the `pomodoro.lua` file.

4. **Configure the Script:**  
   - Enter the OBS text source name where the timer should be displayed.
   - Specify the media source name for sound alerts.
   - Adjust the focus, short break, and long break durations.
   - Customize the messages for each period.
   - Enable Fast Mode if you want accelerated timer progression (ideal for testing).

---

## How to Use

1. **Start the Timer:**  
   Click the **Start Timer** button at the top of the settings panel to begin your Pomodoro sessions.

2. **Stop the Timer:**  
   Use the **Stop Timer** button to halt the timer whenever needed.

3. **Session Management:**  
   The timer automatically stops after the maximum number of focus sessions is reached. You can then reset and restart if desired.

---

## Customization Options

- **OBS Text Source:**  
  Define which text source will display the timer and session information.

- **Sound Alerts:**  
  Set the media source that will play a sound when transitioning between sessions.

- **Timer Durations:**  
  Enter custom durations (in minutes) for focus sessions, short breaks, and long breaks.

- **Display Messages:**  
  Personalize the messages for focus, short break, and long break periods.

- **Fast Mode:**  
  Toggle Fast Mode on to accelerate the timer for testing purposes, where each real second simulates 60 seconds of timer time.

---

Boost your productivity and streamline your streaming sessions with the **Pomodoro Timer for OBS**. Stay focused, take your breaks, and let your audience follow along with your session progress!

This project is based upon this entry on the OBS forum:
https://obsproject.com/forum/resources/pomodoro-pro-timer-for-obs.1859/
