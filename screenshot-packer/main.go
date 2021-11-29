// Application parses the packer verbose log to get configs and
// screenshot in the critical moments of the build process

package main

import (
	"bufio"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"net"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/mitchellh/go-vnc"
	"github.com/hpcloud/tail"
)

var vnc_host string = ""
var vnc_port string = ""
var vnc_password string = ""
var catched_wait_number uint16 = 0
var screenshots_path string = ""

func VncScreenshot(host, port, password, path string) bool {
	nc, err := net.DialTimeout("tcp", host + ":" + port, time.Second*5)
	if err != nil {
		fmt.Println("SCREENSHOT: No connection")
		return false
	}
	defer nc.Close()

	nc.SetReadDeadline(time.Now().Add(time.Second*5))

	ch := make(chan vnc.ServerMessage)

	c, err := vnc.Client(nc, &vnc.ClientConfig{
		Auth: []vnc.ClientAuth{&vnc.PasswordAuth{Password:password}},
		Exclusive:	   false,
		ServerMessageCh: ch,
		ServerMessages:  []vnc.ServerMessage{new(vnc.FramebufferUpdateMessage)},
	})
	if err != nil {
		fmt.Println("SCREENSHOT: No VNC client", err)
		return false
	}

	defer c.Close()

	err = c.FramebufferUpdateRequest(false, 0, 0, c.FrameBufferWidth, c.FrameBufferHeight)
	if err != nil {
		fmt.Println("SCREENSHOT: No framebuffer", err)
		return false
	}

	msg := <-ch

	rects := msg.(*vnc.FramebufferUpdateMessage).Rectangles
	img := image.NewRGBA(image.Rect(0, 0, int(c.FrameBufferWidth), int(c.FrameBufferHeight)))

	for _, rect := range rects {
		w := int(rect.Width)
		//h := int(rect.Height)

		enc := rect.Enc.(*vnc.RawEncoding)
		i := 0
		x := 0
		y := 0
		for _, v := range enc.Colors {
			x = i % w
			y = i / w
			r := uint8(v.R)
			g := uint8(v.G)
			b := uint8(v.B)

			img.Set(int(rect.X) + x, int(rect.Y) + y, color.RGBA{r, g, b, 255})
			i++
		}

	}

	// Save the screenshot
	_ = os.MkdirAll(filepath.Dir(path), 0755)
	f, _ := os.OpenFile(fmt.Sprintf("%s.png", path), os.O_WRONLY|os.O_CREATE, 0600)
	defer f.Close()
	fmt.Println("SCREENSHOT: Saving screenshot", f.Name())
	png.Encode(f, img)

	return true
}

// Runs the waiting process and taking screenshots in the meanwhile.
// At least 2 screenshots will be taken - in the beginning and in the end (-2s) of wait.
// Each minute adds 1 screenshot in the middle to 5 total maximum.
func screenshotWait(dur time.Duration) {
	begin_time := time.Now()
	var wait_max_screenshots uint8 = 5
	var screenshot_counter uint8 = 0
	if dur < time.Duration(wait_max_screenshots) * time.Minute {
		wait_max_screenshots = uint8(dur / time.Minute)
		if wait_max_screenshots == 0 {
			wait_max_screenshots = 1
		}
	}
	screenshot_interval := (dur - 2*time.Second) / time.Duration(wait_max_screenshots)

	for {
		go VncScreenshot(vnc_host, vnc_port, vnc_password, fmt.Sprintf("%s-%04d-%d", screenshots_path, catched_wait_number, screenshot_counter))
		screenshot_counter += 1
		dur_left := begin_time.Sub(time.Now()) + dur
		if dur_left <= 2*time.Second {
			break
		} else if dur_left < screenshot_interval {
			screenshot_interval = dur_left - 2*time.Second
		}
		fmt.Printf("SCREENSHOT: Sleeping for %s (%s left)\n", screenshot_interval, dur_left)
		time.Sleep(screenshot_interval)
	}
	catched_wait_number += 1
}

func main() {
	log_path := os.Args[1]
	screenshots_path = os.Args[2]

	vmx_path := ""

	t, _ := tail.TailFile(log_path, tail.Config{Follow: true})
	for line := range t.Lines {
		// Getting VMX path
		if vmx_path == "" && strings.Contains(line.Text, "Writing VMX to: ") {
			vmx_path = strings.Split(line.Text, "Writing VMX to: ")[1]
			fmt.Println("SCREENSHOT: Found VMX path:", vmx_path)
		}
		if strings.Contains(line.Text, "vmware-vmx: Connecting to VNC...") {
			break
		}
	}

	begin_time := time.Now()

	// Reading the vmx file to get the vnc address and password
	f, _ := os.Open(vmx_path)
	s := bufio.NewScanner(f)
	for s.Scan() {
		line := s.Text()
		if strings.HasPrefix(line, "remotedisplay.vnc.ip =") {
			vnc_host = strings.Split(line, " =")[1]
			vnc_host = strings.Trim(vnc_host, " \"")
		}
		if strings.HasPrefix(line, "remotedisplay.vnc.port =") {
			vnc_port = strings.Split(line, " =")[1]
			vnc_port = strings.Trim(vnc_port, " \"")
		}
		if strings.HasPrefix(line, "remotedisplay.vnc.password =") {
			vnc_password = strings.Split(line, " =")[1]
			vnc_password = strings.Trim(vnc_password, " \"")
		}
	}

	fmt.Println("SCREENSHOT: Found required vnc creds:", vnc_host, vnc_port, vnc_password)

	// Continue listening on the log file to find the moments for screenshot
	for line := range t.Lines {
		if strings.Contains(line.Text, "vmware-vmx: Waiting ") && strings.Contains(line.Text, " for boot...") {
			duration, _ := time.ParseDuration(strings.Split(line.Text, " ")[3])
			screenshotWait(begin_time.Sub(time.Now()) + duration)
		} else if strings.Contains(line.Text, "plugin: [INFO] Waiting ") {
			duration, _ := time.ParseDuration(line.Text[strings.LastIndex(line.Text, " ")+1:])
			if duration > 9 * time.Second {
				screenshotWait(duration)
			}
		}
	}
}
