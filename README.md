# Flowdock Git Hook

Git Post-Receive hook for [Flowdock](http://flowdock.com).

## Note

Version 1.0. supports only source flow tokens. 0.x versions use a deprecated API which will be removed soon.

## Installation

First, you need to install this gem. You need to have Ruby and Rubygems installed in your system.

    $ gem install flowdock-git-hook

Then, download the post-receive hook file to the hooks directory and make it executable

    $ wget -O hooks/post-receive https://raw.github.com/flowdock/flowdock-git-hook/master/post-receive
    $ chmod +x hooks/post-receive

Set the source flow token given to you by the Flowdock git configuration service

    $ git config flowdock.token <source flow token>

After this, you should get updates from your git repo every time you push to it.

## Configuration

Service specific instructions for [Gitlab](https://github.com/flowdock/flowdock-git-hook/wiki/Gitlab) and [Redmine](https://github.com/flowdock/flowdock-git-hook/wiki/Redmine) can be found in [Wiki](https://github.com/flowdock/flowdock-git-hook/wiki).

### Permanent references

By default each push to the `master` branch will generate a new thread containing just the commits that were pushed. Pushes to other branches or tags will be grouped to a single thread containing all the pushed commits. You can configure this behaviour by setting the `permanent-reference` git variable. The value of that configuration parameter should be a comma separated list of regular expressions.

For example to create new threads for each push to the `master` branch and any branch starting with `with-regex-` do this

    $ git config flowdock.permanent-references "refs/heads/master, refs/heads/with-regex-.*"


### Repository name

The repository name displayed in the inbox message can be set with `repository-name`

    $ git config flowdock.repository-name "my repo"


### Repository URL

Each Team Inbox item sent from the post-receive hook can link back to the repository. To configure the URL for the repository, configure a `repository-url`:

    $ git config flowdock.repository-url "http://example.com/mygitviewer/repo"

### Commit URLs

Commit SHAs links in the Team Inbox of Flowdock can be made clickable to view the change on the web. To configure the URL for viewing commits, configure a `commit-url-pattern`:

    $ git config flowdock.commit-url-pattern "http://example.com/mygitviewer/commits/%s"

The `%s` will be replaced with the commit SHA.

### Diff URL

Commit messages in Team Inbox can have a action for viewing the commit diff. To enable the Diff action for comparing commits, configure a `diff-url-pattern`:

     $ git config flowdock.diff-url-pattern "http://example.com/mygitviewer/compare/%s...%s"

## Advanced usage

The git hook allows Flowdock tags to be attached to push messages. If you only need static tags, e.g. git repo name as tag, this can be configured in git config:

    $ git config flowdock.tags git,push

For programmatic control over tagging, you can change how the hook is called in post-receive hook file.

    Flowdock::Git.background_post(ref, before, after, :tags => ["git", "push"])

Note that you can also define token as parameter allowing multiple Flows to be notified.

    Flowdock::Git.background_post(ref, before, after, :token => "flow-token")
    Flowdock::Git.background_post(ref, before, after, :token => "another-flow")

### Usage as a library

You can use the gem as a library from an application, without the need to set configuration parameters on the Git repository. You can pass the required parameters directly like so:

    Flowdock::Git.post(ref, before, after, :token => "flow-token",
                        :repo => "/path/to/repo",
                        :repo_url => "http://example.com/mygitviewer/repo",
                        :commit_url => "http://example.com/mygitviewer/repo/commit/%s",
                        :diff_url => "http://example.com/mygitviewer/repo/compare/%s...%s")

## Example data

The hook uses [GitHub webhook](http://help.github.com/post-receive-hooks/) format.

    payload {
      "after": "122b95a8808ea0cf708fb43b400a377c25c35d7f",
      "before": "2a445d1d348d9d45217cb9c89c12b67d3767ce42",
      "commits": [
        {
          "added": [],
          "author": {
            "email": "raine.virta@nodeta.fi",
            "name": "Raine Virta"
          },
          "id": "122b95a8808ea0cf708fb43b400a377c25c35d7f",
          "message": "yeah!",
          "modified": [
            "TEST_FILE"
          ],
          "removed": [],
          "timestamp": "2010-08-11T13:46:39+03:00"
        }
      ],
      "ref": "refs\/heads\/master",
      "ref_name": "master",
      "repository": {
        "name": "testrepo"
      }
    }
