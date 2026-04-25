package duration

import (
	"io"
	"net/http"
	"strings"
	"time"

	corev1 "k8s.io/api/core/v1"
)

const (
	APIConditionPolicyName = "APICondition"
)

type APIConditionPolicy struct {
	url              string
	expectedResponse string
}

// NewAPIConditionPolicy creates a new policy that checks an HTTP endpoint
func NewAPIConditionPolicy(url, expectedResponse string) Policy {
	return &APIConditionPolicy{
		url:              url,
		expectedResponse: expectedResponse,
	}
}

func (p *APIConditionPolicy) Name() string {
	return APIConditionPolicyName
}

func (p *APIConditionPolicy) URL() string {
	return p.url
}

func (p *APIConditionPolicy) ExpectedResponse() string {
	return p.expectedResponse
}

// Valid is the function the operator calls.
// It returns TRUE if the boost should continue, and FALSE if the boost should end!
func (p *APIConditionPolicy) Valid(pod *corev1.Pod) bool {
	client := http.Client{
		Timeout: 2 * time.Second,
	}

	resp, err := client.Get(p.url)
	if err != nil {
		// Connection failed (app not listening yet). Keep boosting!
		return true
	}
	defer resp.Body.Close()

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return true // Error reading body. Keep boosting!
	}

	bodyString := string(bodyBytes)

	// If the expected string is found in the response, the app is ready!
	// Return FALSE to tell the operator to STOP the boost.
	if strings.Contains(bodyString, p.expectedResponse) {
		return false
	}

	// String didn't match yet. Keep boosting!
	return true
}
