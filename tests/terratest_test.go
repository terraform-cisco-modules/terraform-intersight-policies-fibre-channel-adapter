package test

import (
	"fmt"
	"os"
	"testing"

	iassert "github.com/cgascoig/intersight-simple-go/assert"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestFull(t *testing.T) {
	//========================================================================
	// Setup Terraform options
	//========================================================================

	// Generate a unique name for objects created in this test to ensure we don't
	// have collisions with stale objects
	uniqueId := random.UniqueId()
	instanceName := fmt.Sprintf("test-policies-fc-adapter-%s", uniqueId)

	// Input variables for the TF module
	vars := map[string]interface{}{
		"intersight_keyid":         os.Getenv("IS_KEYID"),
		"intersight_secretkeyfile": os.Getenv("IS_KEYFILE"),
		"name":                     instanceName,
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./full",
		Vars:         vars,
	})

	//========================================================================
	// Init and apply terraform module
	//========================================================================
	defer terraform.Destroy(t, terraformOptions) // defer to ensure that TF destroy happens automatically after tests are completed
	terraform.InitAndApply(t, terraformOptions)
	moid := terraform.Output(t, terraformOptions, "moid")
	assert.NotEmpty(t, moid, "TF module moid output should not be empty")

	//========================================================================
	// Make Intersight API call(s) to validate module worked
	//========================================================================

	// Setup the expected values of the returned MO.
	// This is a Go template for the JSON object, so template variables can be used
	expectedJSONTemplate := `
{
	"Name":        "{{ .name }}",
	"Description": "{{ .name }} Fibre-Channel Adapter Policy.",

	"ErrorDetectionTimeout": 2000,
	"ErrorRecoverySettings": {
	  "ClassId": "vnic.FcErrorRecoverySettings",
	  "Enabled": false,
	  "IoRetryCount": 8,
	  "IoRetryTimeout": 5,
	  "LinkDownTimeout": 30000,
	  "ObjectType": "vnic.FcErrorRecoverySettings",
	  "PortDownTimeout": 30000
	},
	"FlogiSettings": {
	  "ClassId": "vnic.FlogiSettings",
	  "ObjectType": "vnic.FlogiSettings",
	  "Retries": 8,
	  "Timeout": 4000
	},
	"InterruptSettings": {
	  "ClassId": "vnic.FcInterruptSettings",
	  "Mode": "MSIx",
	  "ObjectType": "vnic.FcInterruptSettings"
	},
	"IoThrottleCount": 512,
	"LunCount": 1024,
	"LunQueueDepth": 20,
	"PlogiSettings": {
	  "ClassId": "vnic.PlogiSettings",
	  "ObjectType": "vnic.PlogiSettings",
	  "Retries": 8,
	  "Timeout": 20000
	},
	"ResourceAllocationTimeout": 10000,
	"RxQueueSettings": {
	  "ClassId": "vnic.FcQueueSettings",
	  "Count": 1,
	  "ObjectType": "vnic.FcQueueSettings",
	  "RingSize": 64
	},
	"ScsiQueueSettings": {
	  "ClassId": "vnic.ScsiQueueSettings",
	  "Count": 1,
	  "ObjectType": "vnic.ScsiQueueSettings",
	  "RingSize": 512
	},
	"TxQueueSettings": {
	  "ClassId": "vnic.FcQueueSettings",
	  "Count": 1,
	  "ObjectType": "vnic.FcQueueSettings",
	  "RingSize": 64
	}
}
`
	// Validate that what is in the Intersight API matches the expected
	// The AssertMOComply function only checks that what is expected is in the result. Extra fields in the
	// result are ignored. This means we don't have to worry about things that aren't known in advance (e.g.
	// Moids, timestamps, etc)
	iassert.AssertMOComply(t, fmt.Sprintf("/api/v1/vnic/FcAdapterPolicies/%s", moid), expectedJSONTemplate, vars)
}
