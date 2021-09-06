## What I built

### `AppStatus` LiveView
I've created a LiveView module called `AppStatus` modeled loosely on the `AppLive.Show` module already present in the code.

We try to fetch the app in the connected mount and on success we fetch
the app's status, using a newly created function in the the `Fly.Client` 
module, named `fetch_app_status/3`. 
This function uses GraphQL query (from link in the project's README) to get all relevant status info about the app.

I've used a message & `handle_info` implementation for fetching the status
so the status fetching can be async and not block the UI.

In this `handle_info` we also send a message to ourselves to run the same
callback after a certain amount of time, denoted as `refresh_period` in
the socket assigns. This way we have periodic refreshes of the data, that
can be configured in regards to their frequency.

We also handle 3 events coming from the client, 'refresh`, `select-refresh-period`
and `set-visible`
* The `refresh` event is emitted when the user clicks on the `Refresh` button
in the client and executes an immediate refresh.

* The `select-refresh-period` is emitted when the user changes the 
refresh period in the client's UI and updates the LiveView's state in
the server to reflect the change intended.

* The `set-visible` event is emitted when the visibility of each 
`AppStatus` instance is modified in the frontend. 

There are also some helper functions in this module, the most notable 
being some function components (since we're using the latest LiveView version)
These help de-clutter the template a lot and also help avoid HTML & Tailwind
duplication.

In the template, I've also used a bit of Alpine to handle showing/hiding 
the application status (`AppStatus`) LiveView on each app in the list. 
This is done by clicking the chevron on the top left of each app entry.


I also use a hook `AppStatusHook`, defined in `assets/js/hooks/app_status_hook.js`
to push `set-visible` events to their corresponding liveview, when
the open/close button for each app is clicked, or when the user
clicks away from all apps and they all need to be closed.
This is initiated in `index.html.leex`, in the `li` elements.

I chose this more complex way of handling visibility changes, instead of
using only LiveView events because handling it with Alpine is more
responsive for the user, especially at higher net latencies, where a 
roundtrip to the server is not performed.

We mount a LiveView per app listed and only show one at a time so that the
interface doesn't clutter up and become visually complex.

The template is styled using Tailwind and it's overall structure closely
matches the output of the CLI version for consistency reasons.

I've also added the same AppStatus LiveView to the `Show` module. This
way the user can both check the status at a glance in the app list view
and also have the same live status info in the `Show` details view along
with the rest of the data present there.



## What I didn't built
__Stop/Restart buttons for VM in Instances Table section.__

  Using these [mutations](https://github.com/superfly/flyctl/blob/master/api/resource_vms.go) for information regarding the GraphQL API call for performing such operations. 

  I didn't build this feature,although it doesn't seem be hard to implement,
  because I wasn't sure this component should have functionality outside
  showing status information. On the other hand, it may be handy to have the 
  option of doing a VM restart/stop right there.

## What I would improve or fix if I had more time
* Styling cleanup (eg paddings, margins, colors, typography) & general
  "tightening up". 

* Swapping click - chevron button: More specifically, instead of using the 
  chevron button on each app in the app list view, to open the status
  component I would like to use the click event for that and have a 
  button/link that navigates to the Show details page instead.
  I find the above interaction more intuitive.

* Perform some optimization for initial app index view mounting. Also
  display something on screen while apps are fetched. Maybe a small
  loader animation with some text that informs the user that apps are
  loading.

* Move function components in `AppStatus` to their own module

* Study the API & Fly's architecture a bit more to see if there's
some other functionality that can be implemented in this component.



## How I'd determine if this feature is successful
I would like to see how intuitive a first-time user finds the usage
of this feature. I.e.:

* Would it take more than, say, 1-2 tries to use it "correctly"?

* Would the user actually find the functionality or is it too subtle?

* Is the information presented clearly enough to be digested quickly?

* Does the styling/color selection hinder the readibility?

* Is the structure of the information clear?

* Could the interaction (e.g. clicking) be reduced even more,
  to the minimum required for the component to function?

* Does the user find the information he/she searches for with just a glance?

If the user doesn't even think about the UI & interactions I would rate
this as a success since I believe that things should be kept simple and
as we should stay out of the way of the user.

## What I've learned
* Using function components
* Using new HEEX syntax
* Improved my understanding of using Phoenix LiveView (also TailWind & Alpine)

The implementation took about 8-9 hours since I had so much fun. Also I
need more practice with Tailwind because I find it is the major thing that 
slows me down at this point.


Thank you in advance,

Spiros Makris