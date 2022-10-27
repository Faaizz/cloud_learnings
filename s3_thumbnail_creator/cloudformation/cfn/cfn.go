package cfn

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	awscfn "github.com/aws/aws-sdk-go-v2/service/cloudformation"
	awscfnt "github.com/aws/aws-sdk-go-v2/service/cloudformation/types"
)

var awscfnc *awscfn.Client

func init() {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	awscfnc = awscfn.NewFromConfig(cfg)
}

func CreateStack(name, desc, body string, cfnParams map[string]string) (map[string]string, error) {
	// setup Params
	stackParams := make([]awscfnt.Parameter, len(cfnParams))
	for key, val := range cfnParams {
		stackParams = append(
			stackParams,
			awscfnt.Parameter{
				ParameterKey:   aws.String(key),
				ParameterValue: aws.String(val),
			},
		)
	}
	// create Stack
	params := &awscfn.CreateStackInput{
		StackName: aws.String(name),
		Capabilities: []awscfnt.Capability{
			awscfnt.CapabilityCapabilityIam,
			awscfnt.CapabilityCapabilityAutoExpand,
		},
		TemplateBody: aws.String(body),
		Parameters:   stackParams,
	}

	_, err := awscfnc.CreateStack(context.TODO(), params)
	if err != nil {
		return map[string]string{}, err
	}

	// wait for stack creation to complete
	dsin := &awscfn.DescribeStacksInput{
		StackName: aws.String(name),
	}
	sccw := awscfn.NewStackCreateCompleteWaiter(awscfnc)
	err = sccw.Wait(context.TODO(), dsin, (5 * time.Minute))
	if err != nil {
		return map[string]string{}, err
	}

	// get stack outputs and fetch requested ones
	dsout, err := awscfnc.DescribeStacks(
		context.TODO(),
		dsin,
	)
	if err != nil {
		return map[string]string{}, err
	}
	outMap := make(map[string]string)
	for _, out := range dsout.Stacks[0].Outputs {
		outMap[*out.OutputKey] = *out.OutputValue
	}

	return outMap, nil
}
