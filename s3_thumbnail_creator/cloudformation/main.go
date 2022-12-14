package main

import (
	"fmt"
	"os"
	"time"

	"github.com/Faaizz/cloud_learnings/s3_thumbnail_creator/cloudformation/cb"
	"github.com/Faaizz/cloud_learnings/s3_thumbnail_creator/cloudformation/cfn"

	"go.uber.org/zap"
)

const macroTemplatePath = "s3_thumbnail_creator_macro.yaml"
const buildTemplatePath = "s3_thumbnail_creator_build.yaml"
const creatorTemplatePath = "s3_thumbnail_creator.yaml"

func main() {
	// time execution
	st := time.Now()

	// setup logging
	loggerCore, err := zap.NewDevelopment()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer loggerCore.Sync()
	logger := loggerCore.Sugar()

	logger.Infoln("creating macro stack...")
	fb, err := os.ReadFile(macroTemplatePath)
	if err != nil {
		logger.Error(err)
		os.Exit(1)
	}
	fs := string(fb)

	_, err = cfn.CreateStack(
		"RandomBucketNameMacro",
		"Macro to generate random bucket names",
		fs,
		map[string]string{},
	)
	if err != nil {
		logger.Error(err)
		os.Exit(1)
	}
	logger.Infoln("created macro stack")

	logger.Infoln("creating build stack...")
	fb, err = os.ReadFile(buildTemplatePath)
	if err != nil {
		logger.Error(err)
		os.Exit(1)
	}
	fs = string(fb)

	buildName := "s3_thumbnail_creator_lambda_container_build"
	buildOut, err := cfn.CreateStack(
		"S3ThumbnailCreatorBuild",
		"ECR Repository & CodeBuild Project to build & host thumbnail replication lambda container image",
		fs,
		map[string]string{
			"BuildName":     buildName,
			"GitHubRepoURL": "https://github.com/Faaizz/s3_thumbnail_creator",
		},
	)
	if err != nil {
		logger.Error(err)
		os.Exit(1)
	}
	logger.Infoln("created build stack")

	logger.Infoln("running build...")
	err = cb.RunBuild(buildName)
	if err != nil {
		logger.Error(err)
		os.Exit(1)
	}
	logger.Infoln("built stack")

	logger.Infoln("creating creator stack...")
	fb, err = os.ReadFile(creatorTemplatePath)
	if err != nil {
		logger.Error(err)
		os.Exit(1)
	}
	fs = string(fb)

	// check for ThumbnailCreatorImageURI in build
	thumbnailCreatorImageURI, ok := buildOut["ThumbnailCreatorImageURI"]
	if !ok {
		logger.Infoln("'ThumbnailCreatorImageURI' not outputted from build stack")
		os.Exit(1)
	}
	_, err = cfn.CreateStack(
		"S3ThumbnailCreator",
		"S3 Thumbnail Replicator",
		fs,
		map[string]string{
			"ThumbnailCreatorImageURI": thumbnailCreatorImageURI,
		},
	)
	if err != nil {
		logger.Error(err)
		os.Exit(1)
	}
	logger.Infoln("created creator stack")

	logger.Infof("execution took: %v", time.Since(st))
	os.Exit(0)
}
