# Notes for real-time web log viewer workday (Spiros Makris)


## General
We're building a real-time log viewer for the web dashboard.

The main focus is ease of use and helping the user solve the most common
problems that appear while deploying and running an app on Fly.io.

There are 3 main sources of logs available:
* Logs generated while Fly is launching new VMs, stopping VMs,etc
* VM/app logs
* Fly proxy logs


We want to present these logs in real-time as they come in and also
filtered by source in separate streams or window them by time(historical data).

Log data is to be sourced from NATS stream & Elastic Search

## Navigation

The UI for the log viewer will be a separate section of the dashboard
(logs).

In that section the user's apps are displayed in a list,
along with short info in the card that displays number of errors/warnings per
app instance as well as some health checks results.

When a user clicks on an app he/she is redirected to the apps's log
screen (or to a whole-screen modal).

## App Log view

This screen displays application level logs (ie logs that are associated with the application but not a specific VM/instance).

These include:
* Proxy logs that are not associated with an instance. e.g.
  * e.g an app is crashing and there are no available healthy VMs
* App Deployment: VM start/stopping
* App Scale up/down

### Filtering:
The user can filter app-level logs by:
* region
* time-window (either set only a start-time or both start-end)
* Message level
* Type: proxy, deployment, scaling
* Any other relevant key present in the log data structure

### Searching
Search field that narrows down entries to the ones containing the term
searched. Similar to doing a `tail | grep xxxx`

### Realtime updates
Logs are updated at (near) real-time, since we should end up using
NATS streaming and Elastic Search (Data Streams?). (subscription model)

If for some reason we need to poll, we can have a user set refresh period,
on relevant views.

The volume of logs in the app level should be relatively low compared 
to the instance/VM level.

### Corelating log entries(proxy -> instance):
Since a lot of proxy-level errors are actually app/instance errors.
where possible the user should be able jump between different sources
(more specifically from Proxy logs to Instance logs) by
clicking a link on the appropriate log line.

For example a Proxy log line could indicate the originating VM
in a `deploy` tag. The tag should be clickable and redirect to
the VM/instance log view associated with the logline.

Entries that do not contain an VM ID do not provide this functionality.


### App's VMs/instances
There is also a list of instances associated with the app.

These instances are grouped by region.

Clicking on an instance will open the instances log view.

This view can either be in an accordion-like UI component, or
a link to separate view (or both).

## Instance Log view
This view display logs associated with a specific VM/instance.

Here we display logs from 2 of the 3 sources mentioned above.
* VM/app logs
* Fly proxy logs associated with a VM

VM start/stop & scaling logs are handled at the app level log view.

This view has a toggle-selection for different view modes.
* Single view (all sources merged in a single stream)
* Side-by-side: 2 column view, Fly-proxy / VM logs

### Corelating log entries (proxy -> instance):
In single view clicking on a line that corelates with another
entry, scrolls the view to the appropriate line.

In 2 column mode clicking will scroll the related source 
view in order to bring the corresponding line into view.

### Corelating log entries(time-based):
We can also corelate entries by (approximate) time.
The user can set a time window that the system will consider
as "simultaneous" in regard to 2 entries from different sources.
Hovering or clicking on a line will highight events that are 
considered concurrent (based on the time window setting).

This can be done in both view modes, but will probably be more
useful in 2-column mode by also scrolling into view the
corresponding lines.

### Filtering:
The user can filter instance-level logs, similar to app-level, by:
* time-window (either set only a start-time or both start-end)
* Message level
* Type: proxy, app-logs (in single view mode)
* Any other relevant key present in the log data structure

### Searching
Search field that narrows down entries to the ones containing the term
searched. Similar to doing a `tail | grep xxxx`



__Note__: Entries should be color coded & formatted (eg. level, time/date, type, region, instance, etc). This applies to both app-level & instance-level views.

__Note__: Historical data viewing is fetched from ElasticSearch.

## Systems that need modifiation
  * Filtering may need additional keys in NATS data structure (needs clarification)
  * Direct NATS streaming (already on the way)


## Risks
  * Overcomplifying the system, both for users (making it less user-friendly)
    and the actual implementation.
    Remember this should solve problems and add value.

  * Possible backend performance issues if lots of users are pulling log data 
    simultaneously.


## Later improvements

  * Links from other dashboard related views, eg metrics (high usage, or http error 
    codes link to appropriate instance log at specified time )

  * Notifications for user-set level warnings/errors (email/push notifications with 
    links to corresponding entry/ies)

  * Find more ways to relate entries across sources.

  * Improve color coding/formatting


## How to determine success
Determining success would be evaluated based on how much this feature helps
users and how easy & intuitive it is to them, especially new ones.

Re-iterating from my notes on the first challenge:
* Would it take more than, say, 1-2 tries to use it "correctly"?

* Would the user actually find the functionality or is it too subtle?

* Is the information presented clearly enough to be digested quickly?

* Does the styling/color selection hinder readibility?

* Is the structure of the information clear?

* Could the interaction (e.g. clicking) be reduced even more,
  to the minimum required for the feature to function?

* Does the user find the information he/she searches for with just a glance?

* Minimize navigation and present related information together

* We have utilized and presented as much available information as possible
  to the user, while upholding the above goals.


On the implementation side:
* Code and architecture should not end up overly complex.
* Should be extensible
* Should be modular

