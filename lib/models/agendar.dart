class Agendar {
  final String objectId;
  final String meetingId;
  final String title;
  final order;
  final String contractAddress;
  final String detail;
  final bool canVote;
  int agree;
  int disAgree;
  int noVote;
  int vote;
  Agendar({
    this.objectId,
    this.meetingId,
    this.title = '',
    this.order,
    this.contractAddress,
    this.detail = '',
    this.agree,
    this.disAgree,
    this.noVote,
    this.vote,
    this.canVote,
  });

  void setVote(vote) {
    this.vote = vote;
  }

  void setResult(int agree, int disAgree, int noVote) {
    this.agree = agree;
    this.disAgree = disAgree;
    this.noVote = noVote;
  }
}
