#!/bin/sh

DELETE_SNAP_OLDER_THAN=$(date --date="28 days ago" +%Y-%m-%d)
SNAP_LOCATION="us-west1"

COLOR_GREEN="\e[32m"
END_COLOR="\e[0m"

attachedDisks=$(curl http://metadata.google.internal/computeMetadata/v1/instance/disks/?recursive=true -H Metadata-Flavor:Google --silent | jq -r '.[] | .deviceName')
for diskName in $attachedDisks;
do
	diskZone=$(gcloud compute disks list --filter="name=$diskName" --format="get(zone)")

	echo Attached disk: $diskName
	currentSnapshots=$(gcloud compute snapshots list --filter="creationTimestamp<'$DELETE_SNAP_OLDER_THAN' AND sourceDisk~'.*?$diskName'" --format="get(name)")
	for snapshotName in $currentSnapshots;
	do
		printf "\tDeleting $snapshotName.."
		gcloud compute snapshots delete -q "$snapshotName"
		printf "$COLOR_GREEN done$END_COLOR\n"
	done

	newSnapshotTimestamp=$(date +%Y%m%d%H%M%S)
	printf "\tCreating snapshot $diskName-$newSnapshotTimestamp.."
	gcloud compute disks snapshot $diskName --snapshot-names $diskName-$newSnapshotTimestamp --quiet --no-user-output-enabled --zone $diskZone
	printf "$COLOR_GREEN done$END_COLOR\n"
done

exit

