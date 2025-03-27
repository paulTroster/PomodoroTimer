# Pomodoro Timer for OBS

A versatile and fully customizable Pomodoro Timer script built specifically for OBS Studio. This script helps you manage your focus sessions and breaks while streaming or recording, keeping both you and your audience informed about your progress.

<img width="1469" alt="PomodoroTimerPircute" src="https://github.com/user-attachments/assets/520fa2a7-321d-4cdf-b2d8-7fd22141ded0" />

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

1. **Download the Script Files:**  
   Clone the repository or download all the files from the project. Ensure the following files are located in the same directory:  
   - `config.lua`  
   - `utils.lua`  
   - `timer.lua`  
   - `main.lua`

2. **Launch OBS Studio:**  
   Open OBS Studio and navigate to **Tools > Scripts**.

3. **Add the Script:**  
   Click the **+** button in the Scripts window and select the `main.lua` file.

4. **Configure Script Settings:**  
   In the OBS Scripts interface, adjust the settings such as the OBS text source, media source names, timer durations, and messages according to your preferences.

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
