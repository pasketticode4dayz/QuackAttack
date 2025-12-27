from pynput import keyboard
import pygame
import time
import os

# Path to .wav file (fixed filename)
Sound = "/Users/nathan/Documents/VSCodeProjects/Python/Quack.wav"

def safe_init_mixer():
    try:
        pygame.mixer.init()
        return True
    except Exception as e:
        print('Could not initialize audio mixer:', e)
        return False

sound_effect = None
if safe_init_mixer():
    if os.path.isfile(Sound):
        try:
            sound_effect = pygame.mixer.Sound(Sound)
            print(f'Sound loaded successfully: {Sound}')
        except Exception as e:
            print('Failed to load sound:', e)
            sound_effect = None
    else:
        print(f'Sound file not found: {Sound}')

def on_press(key):
    """Play the sound on any key press if available."""
    global sound_effect
    if sound_effect:
        try:
            # Optional: stop previous sound to prevent overlap
            # sound_effect.stop()
            sound_effect.play()
        except Exception as e:
            print('Error playing sound:', e)

def on_release(key):
    if key == keyboard.Key.esc:
        # Stop listener
        print("\nESC pressed. Exiting...")
        return False


def main():
    print("Keyboard listener started. Press ESC to exit.")
    print("Press any key to play sound...")
    
    # Collect events until released
    with keyboard.Listener(
            on_press=on_press,
            on_release=on_release) as listener:
        listener.join()
    
    print("Listener stopped.")


if __name__ == '__main__':
    main()