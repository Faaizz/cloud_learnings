package cb

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	awscb "github.com/aws/aws-sdk-go-v2/service/codebuild"
	awscbt "github.com/aws/aws-sdk-go-v2/service/codebuild/types"
)

var awscbc *awscb.Client

func init() {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	awscbc = awscb.NewFromConfig(cfg)
}

func RunBuild(name string) error {

	params := &awscb.StartBuildInput{
		ProjectName: aws.String(name),
	}
	_, err := awscbc.StartBuild(
		context.TODO(),
		params,
	)
	if err != nil {
		return err
	}

	lbparams := &awscb.ListBuildsForProjectInput{
		ProjectName: aws.String(name),
	}

	// time biuild started
	sbT := time.Now()
	for {
		lbout, err := awscbc.ListBuildsForProject(
			context.TODO(),
			lbparams,
		)
		if err != nil {
			return err
		}
		if len(lbout.Ids) <= 0 {
			continue
		}

		bid := lbout.Ids[0]
		bgbparams := &awscb.BatchGetBuildsInput{
			Ids: []string{bid},
		}
		bgbout, err := awscbc.BatchGetBuilds(
			context.TODO(),
			bgbparams,
		)
		if err != nil {
			return err
		}
		if len(bgbout.BuildsNotFound) > 0 {
			return errors.New("build not found")
		}
		if len(bgbout.Builds) <= 0 {
			continue
		}
		build := bgbout.Builds[0]
		if build.BuildComplete {
			if build.BuildStatus != awscbt.StatusTypeSucceeded {
				return errors.New("build failed")
			}
			break
		}

		// error out if build has been running for more than 5 minutes
		if time.Since(sbT) > time.Minute*5 {
			return errors.New("build timed out")
		}
		time.Sleep(5 * time.Second)
	}

	return nil
}
