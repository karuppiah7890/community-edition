// Copyright 2020-2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/chromedp/cdproto/browser"
	"github.com/chromedp/chromedp"
)

const oneMinuteInSeconds = 60

func main() {
	var tceTarBallLink string
	const tceTarBallLinkFlag = "tce-tarball-link"
	var tceTarBallPath string
	const tceTarBallPathFlag = "tce-tarball-path"
	flag.StringVar(&tceTarBallLink, tceTarBallLinkFlag, "", "The link or URL to the TCE release tar ball")
	flag.StringVar(&tceTarBallPath, tceTarBallPathFlag, "", "The download path where the TCE release tar ball is downloaded")

	flag.Parse()

	if strings.TrimSpace(tceTarBallLink) == "" {
		log.Fatalf("A TCE release tar ball link must be provided using -%s", tceTarBallLinkFlag)
	}

	if strings.TrimSpace(tceTarBallPath) == "" {
		log.Printf("Warning: No download path has been provided using -%s . The tar ball will be downloaded to a random temporary directory path and path will be logged", tceTarBallPathFlag)
		log.Fatalf("A TCE release tar ball link must be provided using -%s", tceTarBallLinkFlag)
	}

	// create chrome instance
	ctx, cancel := chromedp.NewContext(
		context.Background(),
		chromedp.WithLogf(log.Printf),
	)
	defer cancel()

	// create a timeout as a safety net to prevent any infinite wait loops
	ctx, cancel = context.WithTimeout(ctx, oneMinuteInSeconds*time.Second)
	defer cancel()

	// set up a channel so we can block later while we monitor the download progress
	downloadComplete := make(chan bool)

	// this will be used to capture the file name later
	var downloadGUID string

	// set up a listener to watch the download events and close the channel when complete
	// this could be expanded to handle multiple downloads through creating a guid map,
	// monitor download urls via EventDownloadWillBegin, etc
	chromedp.ListenTarget(ctx, func(v interface{}) {
		if ev, ok := v.(*browser.EventDownloadProgress); ok {
			fmt.Printf("current download state: %s\n", ev.State.String())
			if ev.State == browser.DownloadProgressStateCompleted {
				downloadGUID = ev.GUID
				close(downloadComplete)
			}
		}
	})

	if err := chromedp.Run(ctx,
		// configure headless browser downloads. note that SetDownloadBehaviorBehaviorAllowAndName is
		// preferred here over SetDownloadBehaviorBehaviorAllow so that the file will be named as the GUID.
		// please note that it only works with 92.0.4498.0 or later due to issue 1204880,
		// see https://bugs.chromium.org/p/chromium/issues/detail?id=1204880
		browser.SetDownloadBehavior(browser.SetDownloadBehaviorBehaviorAllowAndName).
			WithDownloadPath(os.TempDir()).
			WithEventsEnabled(true),
		// navigate to the TCE tar ball link
		chromedp.Navigate(tceTarBallLink),
	); err != nil && !strings.Contains(err.Error(), "net::ERR_ABORTED") {
		// Note: Ignoring the net::ERR_ABORTED page error is essential here since downloads
		// will cause this error to be emitted, although the download will still succeed.
		panic(err)
	}

	// This will block until the chromedp listener closes the channel
	<-downloadComplete

	log.Printf("Download Complete")

	// We can predict the exact file location and name here because of how we configured
	// SetDownloadBehavior and WithDownloadPath
	tempDownloadPath := fmt.Sprintf("%v%v", os.TempDir(), downloadGUID)

	if strings.TrimSpace(tceTarBallPath) == "" {
		log.Printf("Download Path: %v", tempDownloadPath)
	} else {
		err := os.Rename(tempDownloadPath, tceTarBallPath)
		if err != nil {
			log.Printf("Error: An error occurred while storing the TCE tar ball in the provided download path %v", tceTarBallPath)
			panic(err)
		}
	}
}
