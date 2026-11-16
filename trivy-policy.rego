# Trivy ignore policy, loaded by scripts/cicd/scan-image.sh when present.
#
# Each rule below is a reviewed exception. Keep the explanation next to the rule, and
# remove the rule once the finding no longer appears in a scan.
package trivy

import rego.v1

default ignore := false

# aws-lambda-rie (Runtime Interface Emulator), shipped in public.ecr.aws/lambda/dotnet.
#
# Why it is on the image: in Lambda, the service provides the Runtime API that the .NET
# bootstrap polls for events. Outside Lambda nothing provides it, so AWS ships RIE to stand
# in for it. /lambda-entrypoint.sh runs RIE only when AWS_LAMBDA_RUNTIME_API is unset, that
# is, during local runs such as test/local/docker-compose.yaml. In Lambda the variable is
# always set and RIE is never executed.
#
# Why it cannot be patched here: RIE is a Go binary copied into the base image, not an OS
# package, so the microdnf upgrade in the Dockerfile does not touch it. Its Go standard
# library is only updated when AWS rebuilds the base image.
#
# Scope: RIE is the only Go binary in the image (checked with "trivy image --list-all-pkgs"),
# so matching Go packages (pkg:golang/) limits this to RIE. Trivy does not pass the file
# path to this policy, so this cannot match on the path directly. If another Go binary is
# added to the image, then revisit this rule.
#
# Only CVEs listed here are ignored. A new RIE finding fails the scan until it is reviewed
# and added.
rie_reviewed_vulnerabilities := {
	# crypto/x509: man-in-the-middle via untrusted intermediate certificates. RIE only
	# serves a local HTTP endpoint and does not verify certificates in that role.
	# Reviewed 2026-11-15 against stdlib v1.26.9.
	"CVE-2026-111943",
}

ignore if {
	startswith(input.PkgIdentifier.PURL, "pkg:golang/")
	input.VulnerabilityID in rie_reviewed_vulnerabilities
}
