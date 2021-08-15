package io.lightfeather.helloworld.services;

import lombok.SneakyThrows;
import org.elasticsearch.action.search.SearchRequest;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.client.RequestOptions;
import org.elasticsearch.client.RestHighLevelClient;
import org.elasticsearch.index.query.BoolQueryBuilder;
import org.elasticsearch.index.query.QueryBuilders;
import org.elasticsearch.search.builder.SearchSourceBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class TestIndexServiceImpl implements TestIndexService {

    @Value("${elasticsearch.index}")
    private String index;

    @Autowired
    RestHighLevelClient restClient;

    @Override
    @SneakyThrows
    public String get(String id) {
        SearchRequest searchRequest = new SearchRequest(index);
        SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();

        BoolQueryBuilder boolQuery = QueryBuilders.boolQuery();
        boolQuery.must(QueryBuilders.matchQuery("_id", id));

        searchSourceBuilder.query(boolQuery);

        SearchResponse searchResponse = restClient.search(searchRequest, RequestOptions.DEFAULT);

        return searchResponse.toString();
    }
}
