from github import Github
import argparse

class ArgumentParserWithDefaults(argparse.ArgumentParser):
	def add_argument(self, *args, help=None, default=None, **kwargs):
		if help is not None:
			kwargs['help'] = help
		if default is not None and args[0] != '-h':
			kwargs['default'] = default
			if help is not None:
				kwargs['help'] += ' Default: {}'.format(default)
		super().add_argument(*args, **kwargs)

parser = ArgumentParserWithDefaults(
	formatter_class=argparse.RawTextHelpFormatter
)

parser.add_argument('-p', '--pr', type=int, default="1", help='pr number', required=True)
parser.add_argument('-g', '--get', type=str, default="author", help='author,repo,branch,title', required=True)

args = parser.parse_args()

g = Github("github_api_key") # github api key 

repo = g.get_repo("gnuradio/gnuradio")

pr = repo.get_pull(args.pr)

if args.get == "author":
	print("%s" % pr.user.login)
elif args.get == "repo":
	print("%s" % pr.head.repo.full_name)
elif args.get == "branch":
	print("%s" % pr.head.ref)
elif args.get == "title":
	print("%s" % pr.title)

